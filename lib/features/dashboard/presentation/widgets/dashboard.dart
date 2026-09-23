import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/analytics/data/datasources/predictive_remote_data_source.dart';
import 'package:firstrproject/features/analytics/data/models/predictive_insight_model.dart';
import 'package:firstrproject/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:firstrproject/features/budget/domain/usecases/update_budget_limit_usecase.dart';
import 'package:firstrproject/features/budget/domain/usecases/update_daily_limit_usecase.dart';
import 'package:firstrproject/features/budget/domain/usecases/update_weekly_limit_usecase.dart';
import 'package:firstrproject/features/transactions/data/datasources/seed_data_source.dart';
import 'package:firstrproject/features/transactions/domain/entities/transaction.dart';
import 'package:firstrproject/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:firstrproject/features/transactions/presentation/screens/all_transactions_screen.dart';
import 'package:firstrproject/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:firstrproject/features/user/data/repositories/user_settings_repository_impl.dart';
import 'package:firstrproject/features/user/domain/entities/user_settings.dart';
import 'package:firstrproject/features/user/domain/repositories/user_settings_repository.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  TimePeriod _period = TimePeriod.monthly;
  final UserSettingsRepository _userSettingsRepository =
      UserSettingsRepositoryImpl();
  late final UpdateDailyLimitUseCase _updateDailyLimitUseCase;
  late final UpdateWeeklyLimitUseCase _updateWeeklyLimitUseCase;
  late final UpdateBudgetLimitUseCase _updateBudgetLimitUseCase;
  final _user = AuthRepositoryImpl().currentUser;
  PredictiveInsight? _predictiveInsight;
  bool _isInsightLoading = false;
  bool _isImportingSeed = false;
  bool _hasInitialLoaded = false;

  _DashboardState() {
    _updateDailyLimitUseCase = UpdateDailyLimitUseCase(_userSettingsRepository);
    _updateWeeklyLimitUseCase = UpdateWeeklyLimitUseCase(_userSettingsRepository);
    _updateBudgetLimitUseCase = UpdateBudgetLimitUseCase(_userSettingsRepository);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDateWeek = date.subtract(Duration(days: date.weekday - 1));
    return startOfWeek.year == startOfDateWeek.year && startOfWeek.month == startOfDateWeek.month && startOfWeek.day == startOfDateWeek.day;
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  String _getPeriodName(AppLocalizations l10n, TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return l10n.daily;
      case TimePeriod.weekly:
        return l10n.weekly;
      case TimePeriod.monthly:
        return l10n.monthly;
    }
  }

  void _showEditLimitDialog(BuildContext context, String periodLabel, double currentLimit) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentLimit.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        title: Text(l10n.setLimit(periodLabel), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: '${l10n.periodLimit(periodLabel)} (${l10n.lyd})',
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
              if (_period == TimePeriod.daily) {
                await _updateDailyLimitUseCase.call(limit);
              } else if (_period == TimePeriod.weekly) {
                await _updateWeeklyLimitUseCase.call(limit);
              } else {
                await _updateBudgetLimitUseCase.call(limit);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _maybeInitialPredictiveInsight(
    List<Transaction> transactions,
    String languageCode,
  ) {
    // Auto-populate the insight ONCE, when spending data first becomes
    // available, so the dashboard isn't empty on open. After that the user
    // refreshes manually via the star button — adding transactions no longer
    // triggers an AI call every time.
    if (_hasInitialLoaded || _isInsightLoading) return;
    final weeklyExpenses = _lastSevenDayExpenses(transactions);
    if (weeklyExpenses.isEmpty) return;
    _hasInitialLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPredictiveInsight(weeklyExpenses, languageCode);
    });
  }

  Future<void> _refreshInsight(
    List<Transaction> transactions,
    String languageCode,
  ) async {
    if (_isInsightLoading) return;
    _hasInitialLoaded = true;
    final weeklyExpenses = _lastSevenDayExpenses(transactions);
    await _loadPredictiveInsight(weeklyExpenses, languageCode);
  }

  Future<void> _loadPredictiveInsight(
    List<Transaction> weeklyExpenses,
    String languageCode,
  ) async {
    if (!mounted) return;
    if (weeklyExpenses.isEmpty) {
      setState(() {
        _predictiveInsight = null;
        _isInsightLoading = false;
      });
      return;
    }

    setState(() {
      _isInsightLoading = true;
      _predictiveInsight = null;
    });

    final insight = await getPredictiveInsight(weeklyExpenses, languageCode);

    if (!mounted) return;
    setState(() {
      _predictiveInsight = insight;
      _isInsightLoading = false;
    });
  }

  List<Transaction> _lastSevenDayExpenses(List<Transaction> transactions) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return transactions
        .where((transaction) =>
            !transaction.isIncome &&
            transaction.createdAt.isAfter(start) &&
            transaction.createdAt.isBefore(now.add(const Duration(seconds: 1))))
        .toList();
  }

  Future<void> _importSeedJson() async {
    final user = _user;
    if (user == null || _isImportingSeed) return;

    setState(() => _isImportingSeed = true);
    try {
      await SeedDataSource().importTransactionsFromJson(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON transactions imported successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isImportingSeed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Transaction> transactions = context.watch<TransactionProvider>().transactions;
    _maybeInitialPredictiveInsight(transactions, l10n.localeName);

    return StreamBuilder<UserSettings>(
      stream: _userSettingsRepository.watchUserSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        double monthlyLimit = settings?.budgetLimit ?? 0.0;
        double weeklyLimit = settings?.weeklyLimit ?? (monthlyLimit / 4.33);
        double dailyLimit = settings?.dailyLimit ?? (monthlyLimit / 30);

        double spentInPeriod = 0.0;
        double limitForPeriod = 0.0;
        String periodLabel = _getPeriodName(l10n, _period);

        if (_period == TimePeriod.daily) {
          spentInPeriod = transactions.where((t) => !t.isIncome && _isToday(t.createdAt)).fold<double>(0.0, (s, t) => s + t.amount);
          limitForPeriod = dailyLimit;
        } else if (_period == TimePeriod.weekly) {
          spentInPeriod = transactions.where((t) => !t.isIncome && _isThisWeek(t.createdAt)).fold<double>(0.0, (s, t) => s + t.amount);
          limitForPeriod = weeklyLimit;
        } else {
          spentInPeriod = transactions.where((t) => !t.isIncome && _isThisMonth(t.createdAt)).fold<double>(0.0, (s, t) => s + t.amount);
          limitForPeriod = monthlyLimit;
        }

        double spentPercentage = limitForPeriod > 0 ? (spentInPeriod / limitForPeriod) * 100 : 0.0;

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 48),
                _buildHeader(l10n),
                const SizedBox(height: 32),
                _buildBalance(transactions, l10n),
                const SizedBox(height: 32),
                _buildPeriodToggle(l10n),
                const SizedBox(height: 24),
                _buildPeriodLimitCard(periodLabel, limitForPeriod, spentInPeriod, spentPercentage, l10n),
                const SizedBox(height: 16),
                _buildAIInsightSection(transactions, l10n),
                const SizedBox(height: 32),
                _buildRecentTransactions(transactions, l10n),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.brandGreen,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.welcomeBack, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                StreamBuilder<String?>(
                  stream: _userSettingsRepository.watchUserSettings().map((s) => s.displayName),
                  builder: (context, snapshot) {
                    final name = snapshot.data;
                    return Text(
                      (name != null && name.isNotEmpty) ? name : 'User',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  },
                ),
              ],
            ),
            const Spacer(),
            if (kDebugMode)
              IconButton(
                tooltip: 'Import JSON',
                icon: _isImportingSeed
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    : const Icon(Icons.upload_file, color: Colors.white70),
                onPressed: _isImportingSeed ? null : _importSeedJson,
              ),
            IconButton(icon: const Icon(Icons.notifications, color: Colors.white70), onPressed: () {}),
          ],
        ),
      );

  Widget _buildBalance(List<Transaction> transactions, AppLocalizations l10n) {
    double totalIncome = transactions.where((t) => t.isIncome).fold<double>(0.0, (acc, t) => acc + t.amount);
    double totalExpense = transactions.where((t) => !t.isIncome).fold<double>(0.0, (acc, t) => acc + t.amount);
    double balance = totalIncome - totalExpense;
    String balanceStr = formatCurrency(balance);
    List<String> parts = balanceStr.split('.');
    String whole = parts[0];
    String decimal = parts.length > 1 ? parts[1] : '00';

    return Center(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: whole, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: '.$decimal', style: const TextStyle(fontSize: 30, color: Colors.grey)),
                TextSpan(text: ' ${l10n.lyd}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.brandGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.2)),
            ),
            child: Text(l10n.totalBalance, style: const TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: TimePeriod.values.map((p) {
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
                      _getPeriodName(l10n, p),
                      style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );

  Widget _buildAIInsightSection(List<Transaction> transactions, AppLocalizations l10n) {
    void onRefresh() => _refreshInsight(transactions, l10n.localeName);
    if (_predictiveInsight != null) {
      return _buildAIInsightCard(_predictiveInsight!, l10n, onRefresh, _isInsightLoading);
    }
    if (_isInsightLoading) {
      return _buildAIInsightLoadingCard(l10n);
    }
    return _buildAIInsightEmptyCard(l10n, onRefresh);
  }

  Widget _buildAIInsightHeader(
    AppLocalizations l10n, {
    required bool isLoading,
    VoidCallback? onRefresh,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.aiInsightTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        if (onRefresh != null)
          IconButton(
            tooltip: l10n.generateInsight,
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                  )
                : const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
          ),
      ],
    );
  }

  Widget _buildAIInsightLoadingCard(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIInsightHeader(l10n, isLoading: true),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.generatingInsight,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightEmptyCard(AppLocalizations l10n, VoidCallback onRefresh) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIInsightHeader(l10n, isLoading: false, onRefresh: onRefresh),
            const SizedBox(height: 16),
            Text(
              l10n.aiInsightEmpty,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(l10n.generateInsight),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.withValues(alpha: 0.25),
                  foregroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightCard(
    PredictiveInsight insight,
    AppLocalizations l10n,
    VoidCallback onRefresh,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIInsightHeader(l10n, isLoading: isLoading, onRefresh: onRefresh),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: '${l10n.spentThisWeek}: '),
                  TextSpan(
                    text: '${formatCurrency(insight.weeklySpent)} ${l10n.lyd}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' on '),
                  TextSpan(
                    text: insight.category,
                    style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Predicted Next Week: ${formatCurrency(insight.predictedNextWeek)} ${l10n.lyd}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              insight.advice,
              style: const TextStyle(color: Color(0xFFB7A7FF), fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodLimitCard(String periodLabel, double limitForPeriod, double spentInPeriod, double spentPercentage, AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCard,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.periodLimit(periodLabel), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showEditLimitDialog(context, periodLabel, limitForPeriod),
                          child: const Icon(Icons.edit, size: 14, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${formatCurrency(limitForPeriod)} ${l10n.lyd}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    _legendDot(Colors.blue, '${l10n.spent} (${spentPercentage.toInt()}%)'),
                    const SizedBox(height: 8),
                    _legendDot(Colors.grey, '${l10n.remaining} (${(100 - spentPercentage).clamp(0, 100).toInt()}%)'),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: (spentPercentage / 100).clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(spentPercentage > 100 ? Colors.red : Colors.blue),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatCurrency(spentInPeriod), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(l10n.spent, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _legendDot(Color color, String text) => Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  Widget _buildRecentTransactions(List<Transaction> transactions, AppLocalizations l10n) {
    // Show only the 5 most recent on dashboard
    final recent = transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.recentTransactions, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllTransactionsScreen())
                  );
                },
                child: Text(l10n.seeAll, style: const TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(l10n.noTransactions, style: const TextStyle(color: Colors.grey)),
          )
        else
          ...recent.map((t) => TransactionTile(transaction: t)),
      ],
    );
  }
}
