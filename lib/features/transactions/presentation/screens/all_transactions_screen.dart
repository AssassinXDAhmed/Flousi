import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/transactions/domain/entities/transaction.dart';
import 'package:firstrproject/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:firstrproject/features/transactions/presentation/widgets/transaction_tile.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transactions = context.watch<TransactionProvider>().transactions;

    // Group transactions by date (ignoring time)
    Map<DateTime, List<Transaction>> grouped = {};
    for (var t in transactions) {
      final date = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(t);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Text(l10n.allTransactions, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 48),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dailyTransactions = grouped[date]!;

          // Calculate daily total spent
          final dailySpent = dailyTransactions
              .where((t) => !t.isIncome)
              .fold<double>(0.0, (sum, t) => sum + t.amount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatGroupDate(date, l10n),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      l10n.spentColon(formatCurrency(dailySpent)),
                      style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ...dailyTransactions.map((t) => TransactionTile(transaction: t)),
              if (index < sortedDates.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: Colors.white.withValues(alpha: 0.05), height: 32),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatGroupDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return l10n.today;
    if (date == yesterday) return l10n.yesterday;

    // For general dates, use localized DateFormat
    final locale = l10n.localeName;
    return DateFormat.yMMMMEEEEd(locale).format(date);
  }
}
