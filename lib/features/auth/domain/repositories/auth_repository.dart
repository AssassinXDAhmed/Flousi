import 'package:firebase_auth/firebase_auth.dart';

/// Abstract contract for authentication. Returns Firebase [User] directly
/// (pragmatic) so the presentation/root layer can read `email`/`displayName`
/// without an extra mapping layer — preserving legacy behavior.
abstract class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});
}
