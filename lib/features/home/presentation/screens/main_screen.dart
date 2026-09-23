import 'package:flutter/material.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/budget/presentation/widgets/budget_page.dart';
import 'package:firstrproject/features/dashboard/presentation/widgets/dashboard.dart';
import 'package:firstrproject/features/debts/presentation/widgets/debts_page.dart';
import 'package:firstrproject/features/profile/presentation/widgets/profile_page.dart';
import 'package:firstrproject/features/subscriptions/presentation/widgets/subscriptions_page.dart';
import 'package:firstrproject/features/transactions/presentation/widgets/add_transaction_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Dashboard(),
    DebtsPage(),
    SubscriptionsPage(),
    BudgetPage(),
    ProfilePage(),
  ];

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: AppTheme.navBlur,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.dashboard),
            BottomNavigationBarItem(icon: const Icon(Icons.account_balance), label: l10n.debts),
            BottomNavigationBarItem(icon: const Icon(Icons.subscriptions), label: l10n.subscriptions),
            BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: l10n.budget),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profile),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddTransactionSheet,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
