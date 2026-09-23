import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/usecases/add_debt_usecase.dart';
import '../../domain/usecases/delete_debt_usecase.dart';
import '../../domain/usecases/toggle_debt_paid_usecase.dart';
import '../../domain/usecases/watch_debts_usecase.dart';

class DebtProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DebtRepository _repository;

  late final WatchDebtsUseCase _watchUseCase;
  late final AddDebtUseCase _addUseCase;
  late final ToggleDebtPaidUseCase _toggleUseCase;
  late final DeleteDebtUseCase _deleteUseCase;

  List<Debt> _debts = [];
  StreamSubscription? _debtSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = false;

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;

  DebtProvider({DebtRepository? repository})
      : _repository = repository ?? DebtRepositoryImpl() {
    _watchUseCase = WatchDebtsUseCase(_repository);
    _addUseCase = AddDebtUseCase(_repository);
    _toggleUseCase = ToggleDebtPaidUseCase(_repository);
    _deleteUseCase = DeleteDebtUseCase(_repository);
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToDebts(user.uid);
      } else {
        _cancelSubscriptions();
      }
    });
  }

  void _listenToDebts(String userId) {
    _cancelSubscriptions();
    _isLoading = true;
    notifyListeners();

    _debtSubscription = _watchUseCase.call(userId).listen(
      (debts) {
        _debts = debts;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('DebtProvider stream error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _cancelSubscriptions() {
    _debtSubscription?.cancel();
    _debtSubscription = null;
    _debts = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDebt({
    required double amount,
    required bool isIOwe,
    required String personOrPlace,
    String? notes,
    DateTime? reminderDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in to add debts';

    try {
      final debt = Debt(
        id: _repository.generateId(),
        userId: user.uid,
        amount: amount,
        isPaid: false,
        isIOwe: isIOwe,
        personOrPlace: personOrPlace,
        notes: notes,
        reminderDate: reminderDate,
        createdAt: DateTime.now(),
      );
      await _addUseCase.call(debt);
    } catch (e) {
      debugPrint('Error adding debt: $e');
      rethrow;
    }
  }

  Future<void> togglePaidStatus(Debt debt) async {
    try {
      await _toggleUseCase.call(debt);
    } catch (e) {
      debugPrint('Error toggling debt status: $e');
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      await _deleteUseCase.call(id);
    } catch (e) {
      debugPrint('Error deleting debt: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _debtSubscription?.cancel();
    super.dispose();
  }
}
