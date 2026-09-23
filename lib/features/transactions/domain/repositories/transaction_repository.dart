import '../entities/transaction.dart';

/// Abstract contract for the transactions data source.
/// The domain layer depends only on this interface (Dependency Inversion).
abstract class TransactionRepository {
  /// Generates a Firestore-compatible document id without writing.
  String generateId();

  Stream<List<Transaction>> watchTransactions(String uid);

  Future<void> addTransaction(Transaction transaction);

  Future<void> updateTransaction(Transaction transaction);

  Future<void> deleteTransaction(String id);
}
