/// Predictive spending insight returned by the AI forecasting model.
class PredictiveInsight {
  final String category;
  final double weeklySpent;
  final double predictedNextWeek;
  final String advice;

  const PredictiveInsight({
    required this.category,
    required this.weeklySpent,
    required this.predictedNextWeek,
    required this.advice,
  });

  factory PredictiveInsight.fromJson(Map<String, dynamic> json) {
    return PredictiveInsight(
      category: json['category'] as String? ?? 'Unknown',
      weeklySpent: (json['weeklySpent'] as num?)?.toDouble() ?? 0.0,
      predictedNextWeek: (json['predictedNextWeek'] as num?)?.toDouble() ?? 0.0,
      advice: json['advice'] as String? ?? '',
    );
  }
}
