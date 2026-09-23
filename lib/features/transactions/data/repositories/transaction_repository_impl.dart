import 'dart:async';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_data_source.dart';

/// Implements [TransactionRepository] against Firestore via the data source.
/// Repository methods throw on failure; the presentation layer (provider)
/// is responsible for catching and reacting (optimistic rollback, etc.).
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _dataSource;
  TransactionRepositoryImpl({TransactionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? TransactionRemoteDataSource();

  @override
  String generateId() => _dataSource.generateId();

  @override
  Stream<List<Transaction>> watchTransactions(String uid) {
    final controller = StreamController<List<Transaction>>();
    late StreamSubscription<List<Transaction>> sub;
    sub = _dataSource.watchByUid(uid).listen(
          controller.add,
          onError: (Object error) {
            // Fallback: query without orderBy and sort in memory.
            sub.cancel();
            // Reassign so onCancel always cancels the live subscription.
            sub = _dataSource.watchByUidUnsorted(uid).listen(
              controller.add,
              onError: controller.addError,
              onDone: controller.close,
            );
          },
          onDone: controller.close,
        );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Future<void> addTransaction(Transaction transaction) =>
      _dataSource.add(transaction);

  @override
  Future<void> updateTransaction(Transaction transaction) =>
      _dataSource.update(transaction);

  @override
  Future<void> deleteTransaction(String id) => _dataSource.delete(id);
}
