import 'package:flutter/material.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/biometric/domain/services/biometric_service.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback onUsePassword;

  const BiometricLockScreen({
    super.key,
    required this.onUnlocked,
    required this.onUsePassword,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Automatically prompt the OS biometric system when the lock appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuthenticate());
  }

  Future<void> _tryAuthenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final l10n = AppLocalizations.of(context)!;
    final success = await _biometricService.authenticate();

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (success) {
      widget.onUnlocked();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.biometricAuthFailed), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _usePassword() async {
    // AuthWrapper owns the sign-out + skip-flag arming so the timing is safe.
    widget.onUsePassword();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint, size: 72, color: AppTheme.brandGreen),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.unlockApp,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.unlockAppDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 32),
                if (_isAuthenticating)
                  const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandGreen),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _tryAuthenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fingerprint),
                          const SizedBox(width: 8),
                          Text(l10n.unlockApp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _usePassword,
                  child: Text(l10n.usePasswordInstead, style: const TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
