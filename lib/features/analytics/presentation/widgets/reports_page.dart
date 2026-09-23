import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/features/categories/domain/entities/category.dart';
import 'package:firstrproject/features/categories/presentation/providers/category_provider.dart';
import 'package:firstrproject/features/transactions/presentation/providers/transaction_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
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

    // Only expenses
    final expenses = transactions.where((t) => !t.isIncome).toList();

    // Group by category
    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      categoryTotals[t.catagory] =
          (categoryTotals[t.catagory] ?? 0) + t.amount;
    }

    // Build entries with matching category data
    final List<_ReportEntry> data = categoryTotals.entries.map((e) {
      final cat = categories.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Category(
          id: e.key,
          name: e.key,
          icon: Icons.category,
          color: Colors.grey,
        ),
      );
      return _ReportEntry(
        categoryId: cat.id,
        name: cat.name,
        amount: e.value,
        color: cat.color,
        icon: cat.icon,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalSpending = data.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Spending Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              const SizedBox(height: 8),

              // --- Donut Chart ---
              if (data.isEmpty)
                _buildEmptyState()
              else ...[
                _buildDonutChart(data, totalSpending),
                const SizedBox(height: 24),
                _buildLegend(data, totalSpending),
                const SizedBox(height: 32),
                _buildCategoryBreakdown(data, totalSpending),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 80, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 24),
          const Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start adding transactions to see\nyour spending breakdown here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(List<_ReportEntry> data, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassCard,
        child: SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
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
                              color: entry.color.withValues(alpha: 0.8), width: 2)
                          : BorderSide.none,
                    );
                  }),
                ),
              ),
              // Center label
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
      ),
    );
  }

  Widget _buildLegend(List<_ReportEntry> data, double total) {
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

  Widget _buildCategoryBreakdown(List<_ReportEntry> data, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...data.asMap().entries.map((mapEntry) {
          final i = mapEntry.key;
          final entry = mapEntry.value;
          final percentage = total > 0 ? (entry.amount / total * 100) : 0.0;

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _touchedIndex == i
                    ? entry.color.withValues(alpha: 0.12)
                    : AppTheme.cardDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _touchedIndex == i
                      ? entry.color.withValues(alpha: 0.4)
                      : Colors.white10,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Category icon with matching color
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: entry.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(entry.icon, color: entry.color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${percentage.toStringAsFixed(1)}% of total spending',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${formatCurrency(entry.amount)} LYD',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: entry.color,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar with category color
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(entry.color),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ReportEntry {
  final String categoryId;
  final String name;
  final double amount;
  final Color color;
  final IconData icon;

  _ReportEntry({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });
}
