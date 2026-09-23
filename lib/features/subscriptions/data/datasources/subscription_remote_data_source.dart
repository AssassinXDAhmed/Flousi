import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/subscription.dart';
import '../models/subscription_model.dart';

class SubscriptionRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateId() => _firestore.collection('subscriptions').doc().id;

  Stream<List<Subscription>> watchByUid(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SubscriptionModel.fromMap(doc.data(), doc.id).toEntity())
            .toList());
  }

  Future<void> add(Subscription subscription) {
    return _firestore
        .collection('subscriptions')
        .doc(subscription.id)
        .set(SubscriptionModel(subscription).toMap());
  }

  Future<void> updateActiveStatus(String id, bool isActive) {
    return _firestore
        .collection('subscriptions')
        .doc(id)
        .update({'isActive': isActive});
  }

  Future<void> delete(String id) {
    return _firestore.collection('subscriptions').doc(id).delete();
  }
}
