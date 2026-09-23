import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/budget/domain/usecases/update_budget_limit_usecase.dart';
import 'package:firstrproject/features/budget/domain/usecases/update_category_budget_usecase.dart';
import 'package:firstrproject/features/categories/presentation/providers/category_provider.dart';
import 'package:firstrproject/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:firstrproject/features/user/data/repositories/user_settings_repository_impl.dart';
import 'package:firstrproject/features/user/domain/entities/user_settings.dart';
import 'package:firstrproject/features/user/domain/repositories/user_settings_repository.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  void _showSetBudgetDialog(
    BuildContext context,
    double currentLimit,
    UpdateBudgetLimitUseCase updateBudgetLimit,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentLimit.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        title: Text(l10n.setMonthlyBudget, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: l10n.budgetLimitLyd,
            labelStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final limit = double.tryParse(controller.text) ?? 0.0;
              await updateBudgetLimit.call(limit);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryBudgetDialog(
    BuildContext context,
    String categoryId,
    String categoryName,
    double currentLimit,
    UpdateCategoryBudgetUseCase updateCategoryBudget,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentLimit.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        title: Text(l10n.setCategoryLimit(categoryName), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: l10n.categoryBudgetLyd(categoryName),
            labelStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final limit = double.tryParse(controller.text) ?? 0.0;
              await updateCategoryBudget.call(categoryId, limit);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transactions = context.watch<TransactionProvider>().transactions;
    final categories = context.watch<CategoryProvider>().categories;

    final UserSettingsRepository userRepo = UserSettingsRepositoryImpl();
    final updateBudgetLimit = UpdateBudgetLimitUseCase(userRepo);
    final updateCategoryBudget = UpdateCategoryBudgetUseCase(userRepo);

    // Group transactions by category for spending
    Map<String, double> spentData = {};
    for (var tx in transactions) {
      if (!tx.isIncome) {
        spentData[tx.catagory] = (spentData[tx.catagory] ?? 0) + tx.amount;
      }
    }

    double totalSpent = spentData.values.fold(0.0, (acc, val) => acc + val);

    return StreamBuilder<UserSettings>(
      stream: userRepo.watchUserSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        double totalBudget = settings?.budgetLimit ?? 0.0;
        Map<String, double> categoryBudgets =
            settings?.categoryBudgets ?? const {};

        double totalPercentage = totalBudget > 0 ? totalSpent / totalBudget : 0.0;

        return ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(l10n.monthlyBudgets, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
            // Total budget card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x332563EB), Color(0x337B56ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.totalMonthlyBudget, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                          onPressed: () => _showSetBudgetDialog(context, totalBudget, updateBudgetLimit),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: l10n.setMonthlyBudget,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: totalBudget.toInt().toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                          TextSpan(text: ' ${l10n.lyd}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalPercentage.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(totalPercentage > 1 ? Colors.red : Colors.blue),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${l10n.spent}: ${formatCurrency(totalSpent)} ${l10n.lyd}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('${(totalPercentage * 100).toInt()}%', style: TextStyle(color: totalPercentage > 1 ? Colors.red : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l10n.categories, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            ...categories.where((c) => c.id != 'income').map((cat) {
              final spent = spentData[cat.id] ?? 0;
              final budget = categoryBudgets[cat.id] ?? (cat.budget ?? 0.0).toDouble();
              final percentage = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
              final isOver = spent > budget && budget > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(cat.icon, color: cat.color),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _showEditCategoryBudgetDialog(context, cat.id, cat.name, budget, updateCategoryBudget),
                                      child: const Icon(Icons.edit, size: 14, color: Colors.blue),
                                    ),
                                  ],
                                ),
                                Text('${(percentage * 100).toInt()}% ${l10n.used}', style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${formatCurrency(spent)} / ${formatCurrency(budget)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                isOver ? l10n.overBudget : '${formatCurrency(budget - spent)} ${l10n.left}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOver ? Colors.red : Colors.grey,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: const Color(0xFF1E293B),
                          valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.red : Colors.blue),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
