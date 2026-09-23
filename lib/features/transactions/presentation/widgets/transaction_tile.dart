import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/categories/domain/entities/category.dart';
import 'package:firstrproject/features/categories/presentation/providers/category_provider.dart';
import 'package:firstrproject/features/transactions/domain/entities/transaction.dart';
import 'package:firstrproject/features/transactions/presentation/widgets/add_transaction_sheet.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const TransactionTile({super.key, required this.transaction});

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        existingTransaction: transaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = context.watch<CategoryProvider>().categories;
    final fallbackCat = categories.isNotEmpty ? categories.first : const Category(id: '', name: '', icon: Icons.error, color: Colors.grey);
    final cat = categories.firstWhere((c) => c.id == transaction.catagory, orElse: () => fallbackCat);
    final dateStr = _formatDate(transaction.createdAt, l10n);
    return InkWell(
      onTap: () => _showEditSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(cat.icon, color: cat.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((transaction.description ?? cat.name).split('\n').first.trim(), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.isIncome ? '+' : '-'}${formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.isIncome ? AppTheme.brandGreen : Colors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _methodColor(transaction.paymentmethod).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getMethodName(transaction.paymentmethod, l10n).toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _methodColor(transaction.paymentmethod)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _methodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Colors.green;
      case PaymentMethod.card: return Colors.blue;
      case PaymentMethod.transfer: return Colors.purple;
    }
  }

  String _getMethodName(PaymentMethod method, AppLocalizations l10n) {
    switch (method) {
      case PaymentMethod.cash: return l10n.cash;
      case PaymentMethod.card: return l10n.card;
      case PaymentMethod.transfer: return l10n.transfer;
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final locale = l10n.localeName;
    final timeStr = DateFormat.jm(locale).format(date);

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return l10n.todayAt(timeStr);
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return l10n.yesterdayAt(timeStr);
    } else {
      return DateFormat.MMMd(locale).add_jm().format(date);
    }
  }
}
