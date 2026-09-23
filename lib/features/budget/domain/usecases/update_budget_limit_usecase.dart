import '../../../user/domain/repositories/user_settings_repository.dart';

class UpdateBudgetLimitUseCase {
  final UserSettingsRepository _repository;
  UpdateBudgetLimitUseCase(this._repository);

  Future<void> call(double limit) => _repository.updateBudgetLimit(limit);
}
