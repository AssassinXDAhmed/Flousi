import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/localization/locale_provider.dart';
import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/biometric/domain/services/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isLoading = true;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final available = await _biometricService.isAvailable();
    final enabled = await _biometricService.isEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;

    if (!value) {
      setState(() => _isToggling = true);
      try {
        await _biometricService.disable();
        if (mounted) setState(() => _biometricEnabled = false);
      } finally {
        if (mounted) setState(() => _isToggling = false);
      }
      return;
    }

    if (!_biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.biometricNotAvailable), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isToggling = true);
    try {
      await _biometricService.enable();
      if (mounted) setState(() => _biometricEnabled = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.biometricEnableFailed), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Text(l10n.settings, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.security,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: AppTheme.glassCard,
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint, color: AppTheme.brandGreen),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.biometricLogin,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(l10n.biometricLoginDesc,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _biometricEnabled,
                          activeTrackColor: AppTheme.brandGreen,
                          onChanged: _isToggling ? null : _toggleBiometric,
                        ),
                      ],
                    ),
                  ),
                  if (!_biometricAvailable && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, left: 4),
                      child: Text(l10n.biometricNotAvailable,
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    ),
                  const SizedBox(height: 32),
                  Text(l10n.language,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l10n.languageDesc,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: AppTheme.glassCard,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _LanguageOption(
                          label: 'English',
                          selected: !localeProvider.isArabic,
                          onTap: () => context.read<LocaleProvider>().setEnglish(),
                        ),
                        const Divider(height: 1, color: Colors.white10, indent: 16, endIndent: 16),
                        _LanguageOption(
                          label: 'العربية',
                          selected: localeProvider.isArabic,
                          onTap: () => context.read<LocaleProvider>().setArabic(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.language, color: AppTheme.brandGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.brandGreen, size: 22)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 22),
          ],
        ),
      ),
    );
  }
}
