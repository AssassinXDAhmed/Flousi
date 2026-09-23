import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  String generateId();
  Stream<List<Subscription>> watchSubscriptions(String userId);
  Future<void> addSubscription(Subscription subscription);
  Future<void> toggleSubscriptionStatus(Subscription subscription);
  Future<void> deleteSubscription(String id);
}
