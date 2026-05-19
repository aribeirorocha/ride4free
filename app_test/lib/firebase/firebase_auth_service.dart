import 'package:firebase_auth/firebase_auth.dart';

/// Email/password auth used with the same derived credentials as the local API.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<String> signInOrRegister({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found' &&
          e.code != 'wrong-password' &&
          e.code != 'invalid-credential') {
        rethrow;
      }
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Firebase sign-in succeeded but no current user');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase ID token is empty');
    }
    return token;
  }

  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken(forceRefresh);
  }

  Future<void> signOut() => _auth.signOut();
}
