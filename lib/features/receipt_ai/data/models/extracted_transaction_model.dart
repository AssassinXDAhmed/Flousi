/// Result of AI extraction from a receipt image.
class ExtractedTransaction {
  final double amount;
  final String category;
  final String note;
  final String method; // "CASH" or "CARD"

  const ExtractedTransaction({
    required this.amount,
    required this.category,
    required this.note,
    required this.method,
  });

  factory ExtractedTransaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;
    return ExtractedTransaction(
      amount: amount,
      category: (json['category'] as String?)?.toLowerCase() ?? 'groceries',
      note: json['note'] as String? ?? '',
      method: (json['method'] as String?)?.toUpperCase() ?? 'CASH',
    );
  }
}
