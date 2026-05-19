import 'package:app_test/app_config.dart';
import 'package:app_test/firebase/firebase_auth_service.dart';
import 'package:app_test/ride4free_api.dart';

/// Obtains an API bearer token (Firebase ID token or local session token).
Future<void> syncRide4FreeApiSession({
  required String email,
  required String password,
  required String displayName,
  Ride4FreeApi? api,
  FirebaseAuthService? firebaseAuth,
}) async {
  final client = api ?? Ride4FreeApi();

  if (Ride4FreeAppConfig.useFirebaseAuth) {
    final auth = firebaseAuth ?? FirebaseAuthService();
    Ride4FreeAuth.token = await auth.signInOrRegister(
      email: email,
      password: password,
      displayName: displayName,
    );
    return;
  }

  try {
    final login = await client.login(email: email, password: password);
    Ride4FreeAuth.token = login.token;
    return;
  } catch (_) {}

  final register = await client.register(
    email: email,
    password: password,
    name: displayName,
  );
  Ride4FreeAuth.token = register.token;
}
