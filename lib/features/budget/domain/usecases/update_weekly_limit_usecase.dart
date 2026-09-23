import '../../../user/domain/repositories/user_settings_repository.dart';

class UpdateWeeklyLimitUseCase {
  final UserSettingsRepository _repository;
  UpdateWeeklyLimitUseCase(this._repository);

  Future<void> call(double limit) => _repository.updateWeeklyLimit(limit);
}
