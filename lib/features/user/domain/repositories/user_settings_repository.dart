import '../entities/user_settings.dart';

/// Shared contract for the `users/{uid}` document. Consumed by the budget,
/// profile and biometric features so a single stream backs them all.
abstract class UserSettingsRepository {
  Stream<UserSettings> watchUserSettings();
  Future<void> updateBudgetLimit(double limit);
  Future<void> updateDailyLimit(double limit);
  Future<void> updateWeeklyLimit(double limit);
  Future<void> updateCategoryBudget(String categoryId, double limit);
  Future<void> setBiometricAuth(bool value);
  Future<double> getBudgetLimit();
}
