import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  AuthRepositoryImpl({AuthRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AuthRemoteDataSource();

  @override
  User? get currentUser => _dataSource.currentUser;

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      return await _dataSource.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw _dataSource.handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _dataSource.signInWithEmailPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _dataSource.handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _dataSource.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _dataSource.handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }
}
