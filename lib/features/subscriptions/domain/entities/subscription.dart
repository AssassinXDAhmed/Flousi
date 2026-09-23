/// Pure domain entity for a subscription / recurring billing.
class Subscription {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final bool isRecurring;
  final String period; // 'Weekly' or 'Monthly'
  final String currency; // 'LYD', 'USD', 'EUR', 'GBP'
  final DateTime nextBillingDate;
  final bool isActive;

  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.isRecurring,
    required this.period,
    required this.currency,
    required this.nextBillingDate,
    this.isActive = true,
  });

  Subscription copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    bool? isRecurring,
    String? period,
    String? currency,
    DateTime? nextBillingDate,
    bool? isActive,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isRecurring: isRecurring ?? this.isRecurring,
      period: period ?? this.period,
      currency: currency ?? this.currency,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
