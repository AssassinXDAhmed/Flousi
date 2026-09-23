import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';
import '../../domain/usecases/watch_transactions_usecase.dart';

/// Holds transaction state for the UI. Delegates all Firestore access to the
/// [TransactionRepository] (Dependency Inversion) and keeps the legacy
/// optimistic-update + offline-friendly behavior.
class TransactionProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransactionRepository _repository;

  late final WatchTransactionsUseCase _watchUseCase;
  late final AddTransactionUseCase _addUseCase;
  late final UpdateTransactionUseCase _updateUseCase;
  late final DeleteTransactionUseCase _deleteUseCase;

  List<Transaction> _transactions = [];
  StreamSubscription? _transactionsSubscription;

  List<Transaction> get transactions => _transactions;

  TransactionProvider({TransactionRepository? repository})
      : _repository = repository ?? TransactionRepositoryImpl() {
    _watchUseCase = WatchTransactionsUseCase(_repository);
    _addUseCase = AddTransactionUseCase(_repository);
    _updateUseCase = UpdateTransactionUseCase(_repository);
    _deleteUseCase = DeleteTransactionUseCase(_repository);
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      _transactionsSubscription?.cancel();
      if (user != null) {
        _fetchTransactions(user.uid);
      } else {
        _transactions = [];
        notifyListeners();
      }
    });
  }

  void _fetchTransactions(String uid) {
    _transactionsSubscription = _watchUseCase.call(uid).listen(
      (transactions) {
        _transactions = transactions;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('TransactionProvider stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('AddTransaction Failed: No authenticated user');
      return;
    }

    final txToSave = transaction.copyWith(
      id: transaction.id.isEmpty ? _repository.generateId() : transaction.id,
      uid: user.uid,
    );

    // Optimistic local update so the UI reflects the change immediately and
    // works offline. We do NOT await the server write because Firestore write
    // futures only resolve on server acknowledgment, which never happens while
    // offline (leaving the add sheet stuck open).
    _transactions.insert(0, txToSave);
    notifyListeners();

    _addUseCase.call(txToSave).catchError((e) {
      debugPrint('Error adding transaction: $e');
      _transactions.removeWhere((t) => t.id == txToSave.id);
      notifyListeners();
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    final Transaction? previous =
        index != -1 ? _transactions[index] : null;

    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
    }

    _updateUseCase.call(transaction).catchError((e) {
      debugPrint('Error updating transaction: $e');
      if (index != -1 && previous != null) {
        _transactions[index] = previous;
        notifyListeners();
      }
    });
  }

  Future<void> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    final Transaction? removed = index != -1 ? _transactions[index] : null;

    if (index != -1) {
      _transactions.removeAt(index);
      notifyListeners();
    }

    _deleteUseCase.call(id).catchError((e) {
      debugPrint('Error deleting transaction: $e');
      if (index != -1 && removed != null) {
        _transactions.insert(index, removed);
        notifyListeners();
      }
    });
  }
}
