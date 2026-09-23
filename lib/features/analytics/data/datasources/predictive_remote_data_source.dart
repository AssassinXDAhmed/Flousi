import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/network/ai_http_client.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../models/predictive_insight_model.dart';

/// Predicts next week's spending for the user's top category. The weekly
/// summary is built on-device and sent to the Flousi AI Cloudflare Worker,
/// which owns the prompt and the Groq API key.
Future<PredictiveInsight?> getPredictiveInsight(
  List<Transaction> transactions,
  String languageCode,
) async {
  try {
    final weeklyTransactions = _transactionsFromLastSevenDays(transactions);
    if (weeklyTransactions.isEmpty) return null;

    final summary = _weeklyCategorySummary(weeklyTransactions);
    if (summary.isEmpty) return null;

    final breakdown = _topCategoryDailyBreakdown(weeklyTransactions);

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return null;

    final response = await postToAiWorker('getPredictiveInsight', idToken, {
      'weeklySummary': summary,
      'dailyBreakdown': breakdown,
      'languageCode': languageCode,
    });
    if (response is! Map<String, dynamic>) {
      debugPrint('AI worker: no predictive insight in response: $response');
      return null;
    }

    return PredictiveInsight.fromJson(response);
  } catch (e) {
    debugPrint('AI worker predictive insight error: $e');
    return null;
  }
}

List<Transaction> _transactionsFromLastSevenDays(List<Transaction> transactions) {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 7));
  return transactions
      .where((transaction) =>
          !transaction.isIncome &&
          transaction.createdAt.isAfter(start) &&
          transaction.createdAt.isBefore(now.add(const Duration(seconds: 1))))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

String _weeklyCategorySummary(List<Transaction> transactions) {
  final totalsByCategory = <String, double>{};
  for (final transaction in transactions) {
    totalsByCategory[transaction.catagory] =
        (totalsByCategory[transaction.catagory] ?? 0) + transaction.amount;
  }

  final entries = totalsByCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return entries
      .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)} LYD')
      .join(', ');
}

String _topCategoryDailyBreakdown(List<Transaction> transactions) {
  final totalsByCategory = <String, double>{};
  for (final transaction in transactions) {
    totalsByCategory[transaction.catagory] =
        (totalsByCategory[transaction.catagory] ?? 0) + transaction.amount;
  }
  if (totalsByCategory.isEmpty) return '';

  final topCategory = totalsByCategory.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;

  final dayCount = <String, int>{};
  final dayTotal = <String, double>{};
  for (final transaction in transactions) {
    if (transaction.catagory != topCategory) continue;
    final c = transaction.createdAt;
    final key =
        '${c.year}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')}';
    dayCount[key] = (dayCount[key] ?? 0) + 1;
    dayTotal[key] = (dayTotal[key] ?? 0) + transaction.amount;
  }

  final days = dayCount.keys.toList()..sort();
  final parts = days
      .map((k) => '$k: ${dayCount[k]} txns, ${dayTotal[k]!.toStringAsFixed(2)} LYD')
      .join('; ');
  return 'Top category "$topCategory" daily breakdown (date: transaction_count, total): $parts';
}
