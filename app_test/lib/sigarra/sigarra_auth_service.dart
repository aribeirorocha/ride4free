import 'package:http/http.dart' as http;

/// Dev/test login — skips Sigarra. Usernames: `tester` or `admin`, password: `test01`.
class TesterAuth {
  TesterAuth._();

  static const String password = 'test01';
  static const Set<String> usernames = {'tester', 'admin'};

  static bool isTesterUsername(String username) =>
      usernames.contains(username.trim().toLowerCase());

  /// API credentials (separate from Sigarra; avoids clashes with @fe.up.pt accounts).
  static ({String email, String apiPassword}) apiCredentials(String username) {
    final user = username.trim().toLowerCase();
    return (email: '$user@ride4free.dev', apiPassword: password);
  }

  static UniversityIdentity? tryBypass(String username, String password) {
    final user = username.trim().toLowerCase();
    if (password.trim() != TesterAuth.password || !usernames.contains(user)) {
      return null;
    }
    return UniversityIdentity(
      username: user,
      displayName: user == 'admin' ? 'Admin (test)' : 'Tester',
    );
  }
}

class UniversityIdentity {
  UniversityIdentity({
    required this.username,
    required this.displayName,
    this.photoUrl,
  });

  final String username;
  final String displayName;
  final String? photoUrl;
}

class SigarraAuthService {
  // ADICIONADO: Permite injetar um cliente HTTP para os testes unitários
  final http.Client? _client;
  SigarraAuthService({http.Client? client}) : _client = client;

  static final Uri _loginUri = Uri.parse(
    'https://sigarra.up.pt/feup/pt/vld_validacao.validacao',
  );
  static final Uri _homeUri = Uri.parse(
    'https://sigarra.up.pt/feup/pt/web_page.inicial',
  );

  Future<UniversityIdentity?> login({
    required String username,
    required String password,
  }) async {
    final bypass = TesterAuth.tryBypass(username, password);
    if (bypass != null) return bypass;

    // ALTERADO: Usa o cliente injetado (testes) ou o cliente real (app)
    final response = await (_client?.post(
      _loginUri,
      body: {'p_user': username, 'p_pass': password},
    ) ?? http.post(
      _loginUri,
      body: {'p_user': username, 'p_pass': password},
    ));

    if (response.statusCode != 200) {
      return null;
    }

    final body = response.body.toLowerCase();
    final hasMetaRefresh =
        body.contains('http-equiv="refresh"') ||
        body.contains("http-equiv='refresh'");

    if (!hasMetaRefresh) {
      return null;
    }

    final cookieHeader = response.headers['set-cookie'];
    
    // ALTERADO: Usa o cliente injetado (testes) ou o cliente real (app)
    final homeResponse = await (_client?.get(
      _homeUri,
      headers: cookieHeader == null ? null : {'cookie': _cookieValue(cookieHeader)},
    ) ?? http.get(
      _homeUri,
      headers: cookieHeader == null ? null : {'cookie': _cookieValue(cookieHeader)},
    ));

    final profileHtml = homeResponse.statusCode == 200 ? homeResponse.body : response.body;
    final parsedName = _extractName(profileHtml);
    final parsedPhoto = _extractPhotoUrl(profileHtml, username);

    return UniversityIdentity(
      username: username,
      displayName: parsedName ?? username,
      photoUrl: parsedPhoto,
    );
  }

  String _cookieValue(String setCookieHeader) {
    return setCookieHeader
        .split(',')
        .map((part) => part.trim().split(';').first)
        .where((part) => part.contains('='))
        .join('; ');
  }

  String? _extractName(String html) {
    final patterns = <RegExp>[
      RegExp(r'Fotografia\s+de\s+([^"<]+)', caseSensitive: false),
      RegExp(r'Bem-?vindo(?:,|\s)+([^<\n]+)', caseSensitive: false),
      RegExp(r'Nome\s*:\s*([^<\n]+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _extractPhotoUrl(String html, String username) {
    final match = RegExp(
      r'''(\/[^"']*(?:fotografias_service|foto_service)\.foto\?[^"']*)''',
      caseSensitive: false,
    ).firstMatch(html);
    if (match != null) {
      return Uri.parse('https://sigarra.up.pt').resolve(match.group(1)!).toString();
    }
    return 'https://sigarra.up.pt/feup/pt/fotografias_service.foto?pct_cod=$username';
  }
}
