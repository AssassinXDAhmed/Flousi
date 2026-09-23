import '../entities/debt.dart';
import '../repositories/debt_repository.dart';

class AddDebtUseCase {
  final DebtRepository _repository;
  AddDebtUseCase(this._repository);

  Future<void> call(Debt debt) => _repository.addDebt(debt);
}
