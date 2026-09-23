import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import '../../domain/entities/transaction.dart';

/// Firestore-aware representation of a [Transaction].
/// All serialization / Timestamp parsing lives here, never on the entity.
class TransactionModel {
  final Transaction entity;

  const TransactionModel(this.entity);

  Map<String, dynamic> toMap() {
    final t = entity;
    return {
      'id': t.id,
      'uid': t.uid,
      'amount': t.amount,
      'catagory': t.catagory,
      'paymentmethod': t.paymentmethod.name,
      'createdAt': Timestamp.fromDate(t.createdAt),
      'description': t.description,
      'isIncome': t.isIncome,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.parse(map['createdAt']);
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(Transaction(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      catagory: map['catagory'] ?? '',
      paymentmethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentmethod'],
        orElse: () => PaymentMethod.cash,
      ),
      createdAt: parsedDate,
      description: map['description'],
      isIncome: map['isIncome'] ?? false,
    ));
  }

  Transaction toEntity() => entity;
}
