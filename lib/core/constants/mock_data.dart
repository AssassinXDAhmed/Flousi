import '../../features/transactions/domain/entities/transaction.dart';

final List<Transaction> mockTransactions = [
  Transaction(
    id: '1',
    uid: 'mock_user',
    amount: 15.00,
    catagory: 'dining',
    paymentmethod: PaymentMethod.cash,
    createdAt: DateTime.now(),
    description: 'Morning Coffee',
    isIncome: false,
  ),
  Transaction(
    id: '2',
    uid: 'mock_user',
    amount: 120.50,
    catagory: 'groceries',
    paymentmethod: PaymentMethod.card,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    description: 'Carrefour Market',
    isIncome: false,
  ),
  Transaction(
    id: '3',
    uid: 'mock_user',
    amount: 40.00,
    catagory: 'transport',
    paymentmethod: PaymentMethod.cash,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    description: 'Fuel Station',
    isIncome: false,
  ),
  Transaction(
    id: '4',
    uid: 'mock_user',
    amount: 450.00,
    catagory: 'income',
    paymentmethod: PaymentMethod.transfer,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    description: 'Freelance Project',
    isIncome: true,
  ),
];
