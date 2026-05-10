import 'package:shared_preferences/shared_preferences.dart';
import '../sigarra/sigarra_auth_service.dart';

class UniversitySessionStore {
  static const String _kLoggedIn = 'university_logged_in';
  static const String _kUsername = 'university_username';
  static const String _kDisplayName = 'university_display_name';
  static const String _kPhotoUrl = 'university_photo_url';

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

  Future<void> markLoggedIn(UniversityIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kUsername, identity.username);
    await prefs.setString(_kDisplayName, identity.displayName);
    if (identity.photoUrl != null && identity.photoUrl!.isNotEmpty) {
      await prefs.setString(_kPhotoUrl, identity.photoUrl!);
    } else {
      await prefs.remove(_kPhotoUrl);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kUsername);
    await prefs.remove(_kDisplayName);
    await prefs.remove(_kPhotoUrl);
  }
}
