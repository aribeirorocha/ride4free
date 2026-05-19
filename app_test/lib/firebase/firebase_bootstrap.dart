import 'package:app_test/app_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initializes Firebase when [Ride4FreeAppConfig.useFirebaseAuth] is true.
Future<bool> initializeFirebase() async {
  if (!Ride4FreeAppConfig.useFirebaseAuth) {
    return false;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e, st) {
    debugPrint('Firebase.initializeApp failed: $e\n$st');
    return false;
  }
}
