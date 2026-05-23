/// Public API URL for phones / release builds.
///
/// Updated automatically when you run `backend/start.sh` (paste manually if needed).
/// Leave empty (`''`) to use localhost / emulator while developing on your PC.
class Ride4FreeAppConfig {
  Ride4FreeAppConfig._();

  static const String apiBaseUrl = 'https://earned-indie-currency-entirely.trycloudflare.com';

  static bool get useRemoteApi => apiBaseUrl.isNotEmpty;
}
