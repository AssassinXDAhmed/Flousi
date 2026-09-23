import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _dataSource;
  SubscriptionRepositoryImpl({SubscriptionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? SubscriptionRemoteDataSource();

  @override
  String generateId() => _dataSource.generateId();

  @override
  Stream<List<Subscription>> watchSubscriptions(String userId) =>
      _dataSource.watchByUid(userId);

  @override
  Future<void> addSubscription(Subscription subscription) =>
      _dataSource.add(subscription);

  @override
  Future<void> toggleSubscriptionStatus(Subscription subscription) =>
      _dataSource.updateActiveStatus(subscription.id, !subscription.isActive);

  @override
  Future<void> deleteSubscription(String id) => _dataSource.delete(id);
}
