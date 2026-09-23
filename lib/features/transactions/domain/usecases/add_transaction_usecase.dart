import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository _repository;
  AddTransactionUseCase(this._repository);

  Future<void> call(Transaction transaction) =>
      _repository.addTransaction(transaction);
}
