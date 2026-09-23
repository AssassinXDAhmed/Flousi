import '../../domain/entities/user_settings.dart';

/// Firestore-aware representation of [UserSettings] (`users/{uid}`).
class UserSettingsModel {
  final UserSettings entity;

  const UserSettingsModel(this.entity);

  factory UserSettingsModel.fromMap(Map<String, dynamic>? data) {
    Map<String, double> categoryBudgets = {};
    final catData = data?['categoryBudgets'] as Map<String, dynamic>?;
    if (catData != null) {
      categoryBudgets =
          catData.map((key, value) => MapEntry(key, (value ?? 0.0).toDouble()));
    }

    return UserSettingsModel(UserSettings(
      budgetLimit: (data?['budgetLimit'] as num?)?.toDouble(),
      dailyLimit: (data?['dailyLimit'] as num?)?.toDouble(),
      weeklyLimit: (data?['weeklyLimit'] as num?)?.toDouble(),
      categoryBudgets: categoryBudgets,
      biometricAuth: data?['biometricAuth'] == true,
      displayName: data?['displayName'] as String?,
    ));
  }

  UserSettings toEntity() => entity;
}
