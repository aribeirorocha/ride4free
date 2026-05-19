/// Public API URL for phones / release builds.
///
/// Updated automatically when you run `backend/start.sh` (paste manually if needed).
/// Leave empty (`''`) to use localhost / emulator while developing on your PC.
class Ride4FreeAppConfig {
  Ride4FreeAppConfig._();

  static const String apiBaseUrl = 'https://discussion-bloggers-orange-wallpapers.trycloudflare.com';

  /// When true, use Firebase Auth ID tokens for API calls (see Docs/Firebase.md).
  static const bool useFirebaseAuth = true;

  static bool get useRemoteApi => apiBaseUrl.isNotEmpty;
}
