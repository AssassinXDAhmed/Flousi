import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class AddSubscriptionUseCase {
  final SubscriptionRepository _repository;
  AddSubscriptionUseCase(this._repository);

  Future<void> call(Subscription subscription) =>
      _repository.addSubscription(subscription);
}
