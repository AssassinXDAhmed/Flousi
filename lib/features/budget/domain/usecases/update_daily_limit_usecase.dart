import '../../../user/domain/repositories/user_settings_repository.dart';

class UpdateDailyLimitUseCase {
  final UserSettingsRepository _repository;
  UpdateDailyLimitUseCase(this._repository);

  Future<void> call(double limit) => _repository.updateDailyLimit(limit);
}
