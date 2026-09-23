import '../repositories/debt_repository.dart';

class WatchDebtsUseCase {
  final DebtRepository _repository;
  WatchDebtsUseCase(this._repository);

  Stream call(String userId) => _repository.watchDebts(userId);
}
