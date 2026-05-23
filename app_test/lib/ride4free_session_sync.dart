import 'package:app_test/ride4free_api.dart';

/// Obtains an API bearer token via local register/login.
Future<void> syncRide4FreeApiSession({
  required String email,
  required String password,
  required String displayName,
  Ride4FreeApi? api,
}) async {
  final client = api ?? Ride4FreeApi();

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
