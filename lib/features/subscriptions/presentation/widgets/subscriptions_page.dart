import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/subscriptions/domain/entities/subscription.dart';
import 'package:firstrproject/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:firstrproject/features/subscriptions/presentation/widgets/add_subscription_sheet.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<SubscriptionProvider>();
    final subscriptions = provider.subscriptions;

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
                  _buildSummaryCard(subscriptions, l10n),
                  const SizedBox(height: 32),
                  Text(
                    l10n.yourSubscriptions,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.blue)),
            )
          else if (subscriptions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(l10n.noSubscriptionsYet, style: const TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _SubscriptionTile(subscription: subscriptions[index]),
                  childCount: subscriptions.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionSheet(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar(AppLocalizations l10n) => SliverAppBar(
        expandedHeight: 120,
        floating: false,
        pinned: true,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(l10n.subscriptions, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        ),
        backgroundColor: AppTheme.bgDark,
      );

  Widget _buildSummaryCard(List<Subscription> subscriptions, AppLocalizations l10n) {
    double monthlyTotal = 0;
    for (var sub in subscriptions) {
      if (!sub.isActive) continue;
      double amount = sub.amount;
      if (sub.period == 'Weekly') {
        amount *= 4.33; // Approx weeks in a month
      }
      monthlyTotal += amount;
    }

    final locale = l10n.localeName;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.totalMonthlyEst, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                monthlyTotal.toStringAsFixed(2),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('USD', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip(Icons.refresh, '${subscriptions.length} ${l10n.active}'),
              const SizedBox(width: 12),
              _infoChip(Icons.calendar_today, l10n.nextBilling(DateFormat.MMMd(locale).format(DateTime.now().add(const Duration(days: 1))))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.blue),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      );

  void _showAddSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSubscriptionSheet(),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final Subscription subscription;
  const _SubscriptionTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.subscriptions, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${subscription.period} • ${l10n.nextBilling(DateFormat.MMMd(locale).format(subscription.nextBillingDate))}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${subscription.amount.toStringAsFixed(2)} ${subscription.currency}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (!subscription.isRecurring)
                  Text(
                    l10n.oneTime,
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
              onSelected: (val) {
                if (val == 'delete') {
                  context.read<SubscriptionProvider>().deleteSubscription(subscription.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
