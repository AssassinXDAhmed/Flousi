import '../../../user/domain/repositories/user_settings_repository.dart';

class UpdateCategoryBudgetUseCase {
  final UserSettingsRepository _repository;
  UpdateCategoryBudgetUseCase(this._repository);

  Future<void> call(String categoryId, double limit) =>
      _repository.updateCategoryBudget(categoryId, limit);
}
