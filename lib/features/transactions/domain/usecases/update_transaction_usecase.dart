import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransactionUseCase {
  final TransactionRepository _repository;
  UpdateTransactionUseCase(this._repository);

  Future<void> call(Transaction transaction) =>
      _repository.updateTransaction(transaction);
}
