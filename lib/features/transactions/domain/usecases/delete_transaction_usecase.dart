import '../repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository _repository;
  DeleteTransactionUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteTransaction(id);
}
