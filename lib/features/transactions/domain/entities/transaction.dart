/// Pure domain entity for a financial transaction.
/// It has no dependency on any data-layer package (Firestore, etc.).
class Transaction {
  final String id;
  final String uid;
  final double amount;
  final String catagory;
  final PaymentMethod paymentmethod;
  final DateTime createdAt;
  final String? description;
  final bool isIncome;

  const Transaction({
    required this.id,
    required this.uid,
    required this.amount,
    required this.catagory,
    required this.paymentmethod,
    required this.createdAt,
    this.description,
    this.isIncome = false,
  });

  Transaction copyWith({
    String? id,
    String? uid,
    double? amount,
    String? catagory,
    PaymentMethod? paymentmethod,
    DateTime? createdAt,
    String? description,
    bool? isIncome,
  }) {
    return Transaction(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      amount: amount ?? this.amount,
      catagory: catagory ?? this.catagory,
      paymentmethod: paymentmethod ?? this.paymentmethod,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}

enum PaymentMethod { cash, card, transfer }
enum TimePeriod { daily, weekly, monthly }
