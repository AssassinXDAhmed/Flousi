import '../repositories/debt_repository.dart';

class DeleteDebtUseCase {
  final DebtRepository _repository;
  DeleteDebtUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteDebt(id);
}
