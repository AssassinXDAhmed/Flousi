import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class ToggleSubscriptionStatusUseCase {
  final SubscriptionRepository _repository;
  ToggleSubscriptionStatusUseCase(this._repository);

  Future<void> call(Subscription subscription) =>
      _repository.toggleSubscriptionStatus(subscription);
}
