import '../repositories/subscription_repository.dart';

class DeleteSubscriptionUseCase {
  final SubscriptionRepository _repository;
  DeleteSubscriptionUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteSubscription(id);
}
