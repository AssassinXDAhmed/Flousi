import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../datasources/user_remote_data_source.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final UserRemoteDataSource _dataSource;
  UserSettingsRepositoryImpl({UserRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? UserRemoteDataSource();

  @override
  Stream<UserSettings> watchUserSettings() => _dataSource.watchUserSettings();

  @override
  Future<void> updateBudgetLimit(double limit) =>
      _dataSource.mergeField({'budgetLimit': limit});

  @override
  Future<void> updateDailyLimit(double limit) =>
      _dataSource.mergeField({'dailyLimit': limit});

  @override
  Future<void> updateWeeklyLimit(double limit) =>
      _dataSource.mergeField({'weeklyLimit': limit});

  @override
  Future<void> updateCategoryBudget(String categoryId, double limit) =>
      _dataSource.mergeField({
        'categoryBudgets': {categoryId: limit},
      });

  @override
  Future<void> setBiometricAuth(bool value) =>
      _dataSource.mergeField({'biometricAuth': value});

  @override
  Future<double> getBudgetLimit() => _dataSource.getBudgetLimit();
}
