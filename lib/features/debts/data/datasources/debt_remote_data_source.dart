import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/debt.dart';
import '../models/debt_model.dart';

class DebtRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateId() => _firestore.collection('debts').doc().id;

  Stream<List<Debt>> watchByUid(String userId) {
    return _firestore
        .collection('debts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => DebtModel.fromMap(doc.data(), doc.id).toEntity())
          .toList();
      // Sort in memory since the composite index might be building
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Future<void> add(Debt debt) {
    return _firestore
        .collection('debts')
        .doc(debt.id)
        .set(DebtModel(debt).toMap());
  }

  Future<void> updatePaidStatus(String id, bool isPaid) {
    return _firestore.collection('debts').doc(id).update({'isPaid': isPaid});
  }

  Future<void> delete(String id) {
    return _firestore.collection('debts').doc(id).delete();
  }
}
