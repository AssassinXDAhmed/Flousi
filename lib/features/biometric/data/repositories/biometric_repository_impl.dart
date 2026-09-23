import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../user/data/repositories/user_settings_repository_impl.dart';
import '../../../user/domain/repositories/user_settings_repository.dart';
import '../../domain/repositories/biometric_repository.dart';
import '../datasources/biometric_local_data_source.dart';

class BiometricRepositoryImpl implements BiometricRepository {
  final BiometricLocalDataSource _localDataSource;
  final UserSettingsRepository _userSettingsRepository;
  final FirebaseAuth _auth;

  BiometricRepositoryImpl({
    BiometricLocalDataSource? localDataSource,
    UserSettingsRepository? userSettingsRepository,
    FirebaseAuth? auth,
  })  : _localDataSource = localDataSource ?? BiometricLocalDataSource(),
        _userSettingsRepository =
            userSettingsRepository ?? UserSettingsRepositoryImpl(),
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<bool> isAvailable() => _localDataSource.isAvailable();

  @override
  Future<bool> isEnabled() async {
    final uid = _uid;
    if (uid == null) return false;
    return _localDataSource.isEnabled(uid);
  }

  @override
  Future<bool> authenticate() => _localDataSource.authenticate();

  @override
  Future<void> enable() async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';

    final ok = await _localDataSource.authenticate();
    if (!ok) throw 'Biometric authentication failed';

    await _localDataSource.setEnabled(uid, true);

    // Mirror to Firestore users/{uid}.biometricAuth (fire-and-forget).
    _userSettingsRepository.setBiometricAuth(true).catchError((e) {
      debugPrint('Failed to sync biometricAuth to Firestore: $e');
    });
  }

  @override
  Future<void> disable() async {
    final uid = _uid;
    if (uid == null) return;

    await _localDataSource.setEnabled(uid, false);

    _userSettingsRepository.setBiometricAuth(false).catchError((e) {
      debugPrint('Failed to sync biometricAuth to Firestore: $e');
    });
  }
}
