import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/add_subscription_usecase.dart';
import '../../domain/usecases/delete_subscription_usecase.dart';
import '../../domain/usecases/toggle_subscription_status_usecase.dart';
import '../../domain/usecases/watch_subscriptions_usecase.dart';

class SubscriptionProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionRepository _repository;

  late final WatchSubscriptionsUseCase _watchUseCase;
  late final AddSubscriptionUseCase _addUseCase;
  late final ToggleSubscriptionStatusUseCase _toggleUseCase;
  late final DeleteSubscriptionUseCase _deleteUseCase;

  List<Subscription> _subscriptions = [];
  StreamSubscription? _subSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = false;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;

  SubscriptionProvider({SubscriptionRepository? repository})
      : _repository = repository ?? SubscriptionRepositoryImpl() {
    _watchUseCase = WatchSubscriptionsUseCase(_repository);
    _addUseCase = AddSubscriptionUseCase(_repository);
    _toggleUseCase = ToggleSubscriptionStatusUseCase(_repository);
    _deleteUseCase = DeleteSubscriptionUseCase(_repository);
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToSubscriptions(user.uid);
      } else {
        _cancelSubscriptions();
      }
    });
  }

  void _listenToSubscriptions(String userId) {
    _cancelSubscriptions();
    _isLoading = true;
    notifyListeners();

    _subSubscription = _watchUseCase.call(userId).listen(
      (subscriptions) {
        _subscriptions = subscriptions;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('SubscriptionProvider stream error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _cancelSubscriptions() {
    _subSubscription?.cancel();
    _subSubscription = null;
    _subscriptions = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSubscription({
    required String name,
    required double amount,
    required bool isRecurring,
    required String period,
    required String currency,
    required DateTime nextBillingDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in to add subscriptions';

    try {
      final subscription = Subscription(
        id: _repository.generateId(),
        userId: user.uid,
        name: name,
        amount: amount,
        isRecurring: isRecurring,
        period: period,
        currency: currency,
        nextBillingDate: nextBillingDate,
        isActive: true,
      );
      await _addUseCase.call(subscription);
    } catch (e) {
      debugPrint('Error adding subscription: $e');
      rethrow;
    }
  }

  Future<void> toggleSubscriptionStatus(Subscription sub) async {
    try {
      await _toggleUseCase.call(sub);
    } catch (e) {
      debugPrint('Error toggling subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _deleteUseCase.call(id);
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _subSubscription?.cancel();
    super.dispose();
  }
}
