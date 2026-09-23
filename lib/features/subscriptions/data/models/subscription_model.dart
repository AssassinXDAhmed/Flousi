import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/subscription.dart';

/// Firestore-aware representation of a [Subscription].
class SubscriptionModel {
  final Subscription entity;

  const SubscriptionModel(this.entity);

  Map<String, dynamic> toMap() {
    final s = entity;
    return {
      'userId': s.userId,
      'name': s.name,
      'amount': s.amount,
      'isRecurring': s.isRecurring,
      'period': s.period,
      'currency': s.currency,
      'nextBillingDate': Timestamp.fromDate(s.nextBillingDate),
      'isActive': s.isActive,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SubscriptionModel(Subscription(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isRecurring: map['isRecurring'] ?? true,
      period: map['period'] ?? 'Monthly',
      currency: map['currency'] ?? 'LYD',
      nextBillingDate: map['nextBillingDate'] is Timestamp
          ? (map['nextBillingDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['nextBillingDate']?.toString() ?? '') ??
              DateTime.now(),
      isActive: map['isActive'] ?? true,
    ));
  }

  Subscription toEntity() => entity;
}
