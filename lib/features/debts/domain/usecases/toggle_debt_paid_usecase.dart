import '../entities/debt.dart';
import '../repositories/debt_repository.dart';

class ToggleDebtPaidUseCase {
  final DebtRepository _repository;
  ToggleDebtPaidUseCase(this._repository);

  Future<void> call(Debt debt) => _repository.togglePaidStatus(debt);
}
