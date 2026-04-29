import 'package:http/http.dart' as http;

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
    final response = await http.post(
      _loginUri,
      body: {'p_user': username, 'p_pass': password},
    );

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
    final homeResponse = await http.get(
      _homeUri,
      headers: cookieHeader == null ? null : {'cookie': _cookieValue(cookieHeader)},
    );

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
    return 'https://sigarra.up.pt/fotografias_service.foto?pct_cod=$username';
  }
}
