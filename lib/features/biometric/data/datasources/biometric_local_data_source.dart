import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local biometric concerns: hardware availability, OS prompt, and the
/// per-user enabled flag stored in SharedPreferences (offline-safe).
class BiometricLocalDataSource {
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _prefKey(String uid) => 'biometric_auth_$uid';

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  Future<bool> isEnabled(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey(uid)) ?? false;
  }

  Future<void> setEnabled(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(uid), value);
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verify your identity to unlock Flousi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometric authenticate failed: $e');
      return false;
    }
  }
}
