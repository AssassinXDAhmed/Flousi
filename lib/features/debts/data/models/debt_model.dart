import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/debt.dart';

/// Firestore-aware representation of a [Debt].
class DebtModel {
  final Debt entity;

  const DebtModel(this.entity);

  Map<String, dynamic> toMap() {
    final d = entity;
    return {
      'userId': d.userId,
      'amount': d.amount,
      'isPaid': d.isPaid,
      'isIOwe': d.isIOwe,
      'personOrPlace': d.personOrPlace,
      'notes': d.notes,
      'reminderDate':
          d.reminderDate != null ? Timestamp.fromDate(d.reminderDate!) : null,
      'createdAt': Timestamp.fromDate(d.createdAt),
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map, String docId) {
    return DebtModel(Debt(
      id: docId,
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] ?? false,
      isIOwe: map['isIOwe'] ?? true,
      personOrPlace: map['personOrPlace'] ?? '',
      notes: map['notes'],
      reminderDate: map['reminderDate'] is Timestamp
          ? (map['reminderDate'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    ));
  }

  Debt toEntity() => entity;
}
