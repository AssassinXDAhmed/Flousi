import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';

import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';

/// Talks directly to Firestore. This is the only place in the transactions
/// feature that knows about the 'expenses' collection.
class TransactionRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a Firestore document id for the 'expenses' collection without
  /// committing a write. Lets the repository/provider build optimistic copies
  /// with a real id before the (non-blocking) server write.
  String generateId() => _firestore.collection('expenses').doc().id;

  Stream<List<Transaction>> watchByUid(String uid) {
    // Note: Using 'expenses' collection.
    // Try to order by createdAt. If it fails due to missing index, fallback to
    // unsorted and sort in memory.
    return _firestore
        .collection('expenses')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()).toEntity())
            .toList())
        .handleError((error) {
      debugPrint(
          'Firestore Error in TransactionRemoteDataSource (trying fallback): $error');
      throw error;
    });
  }

  Stream<List<Transaction>> watchByUidUnsorted(String uid) {
    return _firestore
        .collection('expenses')
        .where('uid', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()).toEntity())
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Future<void> add(Transaction transaction) {
    return _firestore
        .collection('expenses')
        .doc(transaction.id)
        .set(TransactionModel(transaction).toMap());
  }

  Future<void> update(Transaction transaction) {
    return _firestore
        .collection('expenses')
        .doc(transaction.id)
        .update(TransactionModel(transaction).toMap());
  }

  Future<void> delete(String id) {
    return _firestore.collection('expenses').doc(id).delete();
  }
}
