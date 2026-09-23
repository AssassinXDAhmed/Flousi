import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/user_settings_repository_impl.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';

/// Single source of truth for the `users/{uid}` document. Replaces the three
/// independent StreamBuilders that Dashboard, BudgetPage and ProfilePage each
/// opened against Firestore (which tripled the listener cost and caused
/// cold-start permission denials before auth was ready).
///
/// Batch 6: Write methods now follow the same fire-and-forget, optimistic
/// update + rollback pattern as TransactionProvider. The local state updates
/// immediately, the Firestore write fires without awaiting, and on failure
/// the previous state is restored and the error is broadcast via [syncErrors].
class UserSettingsProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserSettingsRepository _repository;

  StreamSubscription? _settingsSubscription;
  StreamSubscription<User?>? _authSubscription;
  UserSettings? _settings;

  // Broadcast stream so the app shell (MainScreen) can surface background
  // sync failures without coupling to the provider's rollback logic.
  final _syncErrors = StreamController<String>.broadcast();

  UserSettings? get settings => _settings;

  /// Emits a human-readable error string whenever a background Firestore
  /// write fails and the optimistic update is rolled back.
  Stream<String> get syncErrors => _syncErrors.stream;

  // ── Convenience getters ─────────────────────────────────────────────────
  double get budgetLimit => _settings?.budgetLimit ?? 0.0;
  double get dailyLimit => _settings?.dailyLimit ?? 0.0;
  double get weeklyLimit => _settings?.weeklyLimit ?? 0.0;
  Map<String, double> get categoryBudgets =>
      _settings?.categoryBudgets ?? const {};
  String? get displayName => _settings?.displayName;

  UserSettingsProvider({UserSettingsRepository? repository})
      : _repository = repository ?? UserSettingsRepositoryImpl() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listen();
      } else {
        _cancel();
      }
    });
  }

  void _listen() {
    _cancel();
    _settingsSubscription = _repository.watchUserSettings().listen(
      (settings) {
        _settings = settings;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('UserSettingsProvider stream error: $error');
      },
    );
  }

  void _cancel() {
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
    _settings = null;
    notifyListeners();
  }

  /// Safely emits to the syncErrors broadcast stream. Guarded against
  /// hot-restart disposal ordering where the stream may already be closed.
  void _emitSyncError(String error) {
    if (!_syncErrors.isClosed) {
      _syncErrors.add(error);
    }
  }

  // ── Write delegates ─────────────────────────────────────────────────────
  // Optimistic local update → fire-and-forget to Firestore → rollback on
  // failure. The presentation layer should NOT await these; close the dialog
  // immediately and let the provider handle background sync.

  void updateBudgetLimit(double limit) {
    if (_settings == null) return;
    final previous = _settings;
    _settings = _settings!.copyWith(budgetLimit: limit);
    notifyListeners();

    _repository.updateBudgetLimit(limit).catchError((e) {
      debugPrint('Error updating budgetLimit: $e');
      _emitSyncError(e.toString());
      _settings = previous;
      notifyListeners();
    });
  }

  void updateDailyLimit(double limit) {
    if (_settings == null) return;
    final previous = _settings;
    _settings = _settings!.copyWith(dailyLimit: limit);
    notifyListeners();

    _repository.updateDailyLimit(limit).catchError((e) {
      debugPrint('Error updating dailyLimit: $e');
      _emitSyncError(e.toString());
      _settings = previous;
      notifyListeners();
    });
  }

  void updateWeeklyLimit(double limit) {
    if (_settings == null) return;
    final previous = _settings;
    _settings = _settings!.copyWith(weeklyLimit: limit);
    notifyListeners();

    _repository.updateWeeklyLimit(limit).catchError((e) {
      debugPrint('Error updating weeklyLimit: $e');
      _emitSyncError(e.toString());
      _settings = previous;
      notifyListeners();
    });
  }

  void updateCategoryBudget(String categoryId, double limit) {
    if (_settings == null) return;
    final previous = _settings;
    final updatedBudgets = Map<String, double>.from(_settings!.categoryBudgets);
    updatedBudgets[categoryId] = limit;
    _settings = _settings!.copyWith(categoryBudgets: updatedBudgets);
    notifyListeners();

    _repository.updateCategoryBudget(categoryId, limit).catchError((e) {
      debugPrint('Error updating categoryBudget: $e');
      _emitSyncError(e.toString());
      _settings = previous;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _settingsSubscription?.cancel();
    _syncErrors.close();
    super.dispose();
  }
}
