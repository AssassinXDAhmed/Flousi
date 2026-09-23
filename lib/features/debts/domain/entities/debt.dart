/// Pure domain entity for a debt/loan record.
class Debt {
  final String id;
  final String userId;
  final double amount;
  final bool isPaid;
  final bool isIOwe; // true if user owes, false if someone owes user
  final String personOrPlace;
  final String? notes;
  final DateTime? reminderDate;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.userId,
    required this.amount,
    required this.isPaid,
    required this.isIOwe,
    required this.personOrPlace,
    this.notes,
    this.reminderDate,
    required this.createdAt,
  });

  Debt copyWith({
    String? id,
    String? userId,
    double? amount,
    bool? isPaid,
    bool? isIOwe,
    String? personOrPlace,
    String? notes,
    DateTime? reminderDate,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      isIOwe: isIOwe ?? this.isIOwe,
      personOrPlace: personOrPlace ?? this.personOrPlace,
      notes: notes ?? this.notes,
      reminderDate: reminderDate ?? this.reminderDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
