import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_settings.dart';
import '../models/user_settings_model.dart';

/// Talks directly to Firestore. Only place that knows about the `users`
/// collection.
class UserRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<UserSettings> watchUserSettings() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserSettingsModel.fromMap(doc.data()).toEntity());
  }

  Future<void> mergeField(Map<String, dynamic> fields) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .set(fields, SetOptions(merge: true));
  }

  Future<double> getBudgetLimit() async {
    final uid = _uid;
    if (uid == null) return 0.0;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return (doc.data()?['budgetLimit'] ?? 0.0).toDouble();
    }
    return 0.0;
  }
}
