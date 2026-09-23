import 'package:flutter/material.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:firstrproject/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:firstrproject/features/biometric/domain/services/biometric_service.dart';
import 'package:firstrproject/features/profile/presentation/screens/settings_screen.dart';
import 'package:firstrproject/features/analytics/presentation/widgets/reports_page.dart';
import 'package:firstrproject/features/analytics/presentation/widgets/spending_donut.dart';
import 'package:firstrproject/features/user/data/repositories/user_settings_repository_impl.dart';
import 'package:firstrproject/features/user/domain/repositories/user_settings_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _handleLogout(BuildContext context) async {
    BiometricService().skipNextSignIn = true;
    await SignOutUseCase(AuthRepositoryImpl()).call();
  }

  void _openReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authRepo = AuthRepositoryImpl();
    final UserSettingsRepository userRepo = UserSettingsRepositoryImpl();
    final user = authRepo.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.brandGreen,
              child: Icon(Icons.person, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            StreamBuilder<String?>(
              stream: userRepo.watchUserSettings().map((s) => s.displayName),
              builder: (context, snapshot) {
                final name = snapshot.data;
                return Text(
                  (name != null && name.isNotEmpty) ? name : l10n.userName,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              },
            ),
            Text(user?.email ?? 'user@example.com',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // Spending overview with "show full reports" button top-right.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(l10n.spendingOverview,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _openReports(context),
                  icon: const Icon(Icons.analytics,
                      size: 16, color: AppTheme.brandGreen),
                  label: Text(
                    l10n.showFullSpendingReports,
                    style: const TextStyle(
                        color: AppTheme.brandGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const SpendingDonut(),
            const SizedBox(height: 16),

            // Button to display full reports.
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _openReports(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.viewFullReports,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),

            _buildProfileButton(
              context,
              label: l10n.settings,
              icon: Icons.settings,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _handleLogout(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.logout,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context,
      {required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
