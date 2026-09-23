import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/features/categories/domain/entities/category.dart';
import 'package:firstrproject/features/categories/presentation/providers/category_provider.dart';
import 'package:firstrproject/features/transactions/presentation/providers/transaction_provider.dart';

class SpendingDonut extends StatefulWidget {
  final double size;
  final bool showLegend;

  const SpendingDonut({
    super.key,
    this.size = 260,
    this.showLegend = true,
  });

  @override
  State<SpendingDonut> createState() => _SpendingDonutState();
}

class _SpendingDonutState extends State<SpendingDonut>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final categories = context.watch<CategoryProvider>().categories;

    final expenses = transactions.where((t) => !t.isIncome).toList();

    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      categoryTotals[t.catagory] =
          (categoryTotals[t.catagory] ?? 0) + t.amount;
    }

    final List<_DonutEntry> data = categoryTotals.entries.map((e) {
      final cat = categories.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Category(
          id: e.key,
          name: e.key,
          icon: Icons.category,
          color: Colors.grey,
        ),
      );
      return _DonutEntry(
        name: cat.name,
        amount: e.value,
        color: cat.color,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalSpending = data.fold<double>(0, (sum, e) => sum + e.amount);

    if (data.isEmpty) {
      return _buildEmpty();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          children: [
            _buildChart(data, totalSpending),
            if (widget.showLegend) ...[
              const SizedBox(height: 24),
              _buildLegend(data, totalSpending),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline,
              size: 64, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<_DonutEntry> data, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard,
      child: SizedBox(
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 70,
                startDegreeOffset: -90,
                sections: List.generate(data.length, (i) {
                  final isTouched = i == _touchedIndex;
                  final entry = data[i];
                  return PieChartSectionData(
                    value: entry.amount,
                    color: entry.color,
                    radius: isTouched ? 65 : 55,
                    title: '',
                    borderSide: isTouched
                        ? BorderSide(
                            color: entry.color.withValues(alpha: 0.8),
                            width: 2)
                        : BorderSide.none,
                  );
                }),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _touchedIndex >= 0 && _touchedIndex < data.length
                      ? data[_touchedIndex].name
                      : 'Total',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _touchedIndex >= 0 && _touchedIndex < data.length
                      ? formatCurrency(data[_touchedIndex].amount)
                      : formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'LYD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<_DonutEntry> data, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: data.map((entry) {
          final percentage = (entry.amount / total * 100).round();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.name} ($percentage%)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DonutEntry {
  final String name;
  final double amount;
  final Color color;

  _DonutEntry({
    required this.name,
    required this.amount,
    required this.color,
  });
}
