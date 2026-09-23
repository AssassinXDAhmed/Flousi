import '../repositories/subscription_repository.dart';

class WatchSubscriptionsUseCase {
  final SubscriptionRepository _repository;
  WatchSubscriptionsUseCase(this._repository);

  Stream call(String userId) => _repository.watchSubscriptions(userId);
}
