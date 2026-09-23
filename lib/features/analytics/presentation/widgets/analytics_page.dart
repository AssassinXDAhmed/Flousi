import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/features/categories/presentation/providers/category_provider.dart';
import 'package:firstrproject/features/transactions/domain/entities/transaction.dart';
import 'package:firstrproject/features/transactions/presentation/providers/transaction_provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  TimePeriod _period = TimePeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final categories = context.watch<CategoryProvider>().categories;

    // Filter to only expenses based on period
    final now = DateTime.now();
    final expenses = transactions.where((t) {
      if (t.isIncome) return false;
      if (_period == TimePeriod.daily) {
        return t.createdAt.year == now.year && t.createdAt.month == now.month && t.createdAt.day == now.day;
      } else if (_period == TimePeriod.weekly) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final tStart = t.createdAt.subtract(Duration(days: t.createdAt.weekday - 1));
        return startOfWeek.year == tStart.year && startOfWeek.month == tStart.month && startOfWeek.day == tStart.day;
      } else {
        return t.createdAt.year == now.year && t.createdAt.month == now.month;
      }
    }).toList();

    // Group by category
    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      categoryTotals[t.catagory] = (categoryTotals[t.catagory] ?? 0) + t.amount;
    }

    // Convert to _PieEntry
    final List<_PieEntry> data = categoryTotals.entries.map((e) {
      final cat = categories.firstWhere(
        (c) => c.id == e.key,
        orElse: () => categories.isNotEmpty ? categories.first : throw Exception('No categories available'),
      );
      return _PieEntry(cat.name, e.value, cat.color);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    final totalSpending = data.fold<double>(0, (sum, e) => sum + e.value);

    // Group by payment method
    double cashSpent = expenses.where((t) => t.paymentmethod == PaymentMethod.cash).fold(0.0, (s, t) => s + t.amount);
    double cardSpent = expenses.where((t) => t.paymentmethod == PaymentMethod.card || t.paymentmethod == PaymentMethod.transfer).fold(0.0, (s, t) => s + t.amount);
    int cashPercentage = totalSpending > 0 ? (cashSpent / totalSpending * 100).round() : 0;
    int cardPercentage = totalSpending > 0 ? (cardSpent / totalSpending * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        const SizedBox(height: 48),
        const Center(child: Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
        const SizedBox(height: 32),
        _buildPeriodToggle(),
        const SizedBox(height: 32),
        if (data.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No expense data to display for this period.', style: TextStyle(color: Colors.grey)),
          ))
        else ...[
          SizedBox(
            height: 256,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 70,
                    sections: data.map((e) => PieChartSectionData(
                      value: e.value,
                      color: e.color,
                      radius: 90,
                      title: '',
                    )).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total Spending', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(totalSpending.toStringAsFixed(0), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('LYD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _BreakdownCard(icon: Icons.money, iconColor: Colors.green, label: 'Cash', amount: cashSpent, percentage: cashPercentage)),
                const SizedBox(width: 16),
                Expanded(child: _BreakdownCard(icon: Icons.credit_card, iconColor: Colors.blue, label: 'Card/Transfer', amount: cardSpent, percentage: cardPercentage)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildTopCategories(data, totalSpending, categories),
        ],
      ],
    );
  }

  Widget _buildPeriodToggle() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [TimePeriod.daily, TimePeriod.weekly, TimePeriod.monthly].map((p) {
              final selected = _period == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _period = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p.name[0].toUpperCase() + p.name.substring(1),
                      style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );

  Widget _buildTopCategories(List<_PieEntry> data, double total, List<dynamic> categories) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Top Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          ...data.map((e) {
            final cat = categories.firstWhere((c) => c.name == e.name);
            final percentage = (e.value / total * 100).round();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCard,
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: e.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(cat.icon, color: e.color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                          Text('$percentage% of total', style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    Text('${formatCurrency(e.value)} LYD', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            );
          }),
        ],
      );
}

class _PieEntry {
  final String name;
  final double value;
  final Color color;
  _PieEntry(this.name, this.value, this.color);
}

class _BreakdownCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double amount;
  final int percentage;

  const _BreakdownCard({
    required this.icon, required this.iconColor,
    required this.label, required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: amount.toInt().toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const TextSpan(text: ' LYD', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
          const SizedBox(height: 4),
          Text('$percentage%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }
}
