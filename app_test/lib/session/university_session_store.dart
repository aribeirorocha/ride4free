import 'package:app_test/firebase/firebase_auth_service.dart';
import 'package:app_test/ride4free_session_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sigarra/sigarra_auth_service.dart';
import '../ride4free_api.dart';

class UniversitySessionStore {
  static const String _kLoggedIn = 'university_logged_in';
  static const String _kUsername = 'university_username';
  static const String _kDisplayName = 'university_display_name';
  static const String _kPhotoUrl = 'university_photo_url';

  final Ride4FreeApi _api;
  final FirebaseAuthService? _firebaseAuth;
  UniversitySessionStore({Ride4FreeApi? api, FirebaseAuthService? firebaseAuth})
      : _api = api ?? Ride4FreeApi(),
        _firebaseAuth = firebaseAuth;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  Future<UniversityIdentity?> identity() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_kUsername);
    final displayName = prefs.getString(_kDisplayName);
    if (username == null || displayName == null) {
      return null;
    }
    return UniversityIdentity(
      username: username,
      displayName: displayName,
      photoUrl: prefs.getString(_kPhotoUrl),
    );
  }

  /// Faz a ponte entre o Sigarra e o teu Backend Local
  Future<void> markLoggedIn(UniversityIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final String userEmail = '${identity.username}@fe.up.pt';
      final String userPass = 'pass_${identity.username}';

      await syncRide4FreeApiSession(
        email: userEmail,
        password: userPass,
        displayName: identity.displayName,
        api: _api,
        firebaseAuth: _firebaseAuth,
      );

      // 4. Guardar os dados locais nas SharedPreferences
      await prefs.setBool(_kLoggedIn, true);
      await prefs.setString(_kUsername, identity.username);
      await prefs.setString(_kDisplayName, identity.displayName);
      if (identity.photoUrl != null && identity.photoUrl!.isNotEmpty) {
        await prefs.setString(_kPhotoUrl, identity.photoUrl!);
      } else {
        await prefs.remove(_kPhotoUrl);
      }
      
      // ignore: avoid_print
      print("Sessão sincronizada com backend local. Token ativo.");

    } catch (e) {
      // ignore: avoid_print
      print("Erro crítico na sincronização com o backend: $e");
      // Opcional: podes re-lançar o erro se quiseres impedir o login caso o backend esteja offline
      rethrow; 
    }
  }

  Future<void> clear({FirebaseAuthService? firebaseAuth}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kUsername);
    await prefs.remove(_kDisplayName);
    await prefs.remove(_kPhotoUrl);

    final auth = firebaseAuth ?? _firebaseAuth;
    if (auth != null) {
      await auth.signOut();
    }
    Ride4FreeAuth.token = null;
  }
}