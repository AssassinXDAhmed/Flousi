import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/debts/domain/entities/debt.dart';
import 'package:firstrproject/features/debts/presentation/providers/debt_provider.dart';
import 'package:firstrproject/features/debts/presentation/widgets/add_debt_sheet.dart';

class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DebtProvider>();
    final debts = provider.debts;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(l10n),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebtSummary(debts, l10n),
                  const SizedBox(height: 32),
                  Text(l10n.recentDebts, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (provider.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.blue)))
          else if (debts.isEmpty)
            SliverFillRemaining(child: Center(child: Text(l10n.noDebtsYet, style: const TextStyle(color: Colors.grey))))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DebtTile(debt: debts[index]),
                  childCount: debts.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtSheet(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar(AppLocalizations l10n) => SliverAppBar(
        expandedHeight: 120,
        pinned: true,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(l10n.debtsAndLoans, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        ),
        backgroundColor: AppTheme.bgDark,
      );

  Widget _buildDebtSummary(List<Debt> debts, AppLocalizations l10n) {
    double iOweTotal = 0;
    double owedToMeTotal = 0;

    for (var debt in debts) {
      if (debt.isPaid) continue;
      if (debt.isIOwe) {
        iOweTotal += debt.amount;
      } else {
        owedToMeTotal += debt.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _summaryCard(l10n.iOwe, iOweTotal, Colors.redAccent, l10n),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(l10n.owedToMe, owedToMeTotal, Colors.greenAccent, l10n),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, double amount, Color color, AppLocalizations l10n) => Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              l10n.amountLyd(amount.toStringAsFixed(0)),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      );

  void _showAddDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddDebtSheet(),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  const _DebtTile({required this.debt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;

    return Opacity(
      opacity: debt.isPaid ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: debt.isPaid ? Colors.transparent : Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (debt.isIOwe ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  debt.isIOwe ? Icons.arrow_outward : Icons.arrow_downward,
                  color: debt.isIOwe ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personOrPlace,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: debt.isPaid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (debt.notes != null && debt.notes!.isNotEmpty)
                      Text(debt.notes!, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (debt.reminderDate != null && !debt.isPaid)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(DateFormat.MMMd(locale).format(debt.reminderDate!), style: const TextStyle(color: Colors.blue, fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.amountLyd(debt.amount.toStringAsFixed(2)),
                    style: TextStyle(fontWeight: FontWeight.bold, color: debt.isPaid ? Colors.grey : Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (debt.isPaid)
                        const Icon(Icons.check_circle, size: 14, color: Colors.green)
                      else
                        const Icon(Icons.pending, size: 14, color: Colors.orange),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'toggle', child: Text(debt.isPaid ? l10n.markAsUnpaid : l10n.markAsPaid)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
                onSelected: (val) {
                  if (val == 'toggle') {
                    context.read<DebtProvider>().togglePaidStatus(debt);
                  } else if (val == 'delete') {
                    context.read<DebtProvider>().deleteDebt(debt.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
