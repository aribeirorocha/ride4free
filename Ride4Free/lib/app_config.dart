/// Public API URL for phones / release builds.
///
/// Updated automatically when you run `backend/start.sh` (paste manually if needed).
/// Leave empty (`''`) to use localhost / emulator while developing on your PC.
///
/// No trailing slash, e.g. `https://xyz.trycloudflare.com` (not `...com/`).
class Ride4FreeAppConfig {
  Ride4FreeAppConfig._();

  static const String apiBaseUrl = 'https://permits-willing-such-resorts.trycloudflare.com';

  static bool get useRemoteApi => apiBaseUrl.isNotEmpty;
}
