import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class WatchTransactionsUseCase {
  final TransactionRepository _repository;
  WatchTransactionsUseCase(this._repository);

  Stream<List<Transaction>> call(String uid) =>
      _repository.watchTransactions(uid);
}
