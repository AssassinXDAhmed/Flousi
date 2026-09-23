import 'package:flutter_test/flutter_test.dart';

import 'package:firstrproject/core/utils/formatting.dart';
import 'package:firstrproject/features/receipt_ai/data/models/extracted_transaction_model.dart';

void main() {
  group('Core Unit Tests', () {
    test('formatCurrency formats Libyan Dinar correctly', () {
      final formatted = formatCurrency(1250.5);
      expect(formatted, contains('1,250.50'));
    });

    test('ExtractedTransaction deserializes from JSON correctly', () {
      final json = {
        'amount': 45.5,
        'category': 'groceries',
        'note': 'Test receipt note',
        'method': 'CASH',
      };
      final transaction = ExtractedTransaction.fromJson(json);
      expect(transaction.amount, 45.5);
      expect(transaction.category, 'groceries');
      expect(transaction.note, 'Test receipt note');
      expect(transaction.method, 'CASH');
    });
  });
}
