/// Pure domain entity for the current user's settings document
/// (Firestore `users/{uid}`). Fields are nullable to preserve the legacy
/// "absent = use widget default" behavior; the presentation layer applies
/// its own fallbacks (e.g. weeklyLimit ?? monthlyLimit / 4.33).
class UserSettings {
  final double? budgetLimit;
  final double? dailyLimit;
  final double? weeklyLimit;
  final Map<String, double> categoryBudgets;
  final bool biometricAuth;
  final String? displayName;

  const UserSettings({
    this.budgetLimit,
    this.dailyLimit,
    this.weeklyLimit,
    this.categoryBudgets = const {},
    this.biometricAuth = false,
    this.displayName,
  });

  UserSettings copyWith({
    double? budgetLimit,
    double? dailyLimit,
    double? weeklyLimit,
    Map<String, double>? categoryBudgets,
    bool? biometricAuth,
    String? displayName,
  }) {
    return UserSettings(
      budgetLimit: budgetLimit ?? this.budgetLimit,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      weeklyLimit: weeklyLimit ?? this.weeklyLimit,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      displayName: displayName ?? this.displayName,
    );
  }
}
