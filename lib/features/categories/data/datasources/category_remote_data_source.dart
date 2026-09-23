import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category.dart';
import '../models/category_model.dart';

/// Talks directly to Firestore. Only place that knows about the 'categories'
/// collection.
class CategoryRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Category>> watchAll() {
    return _firestore.collection('categories').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) =>
                CategoryModel.fromMap(doc.data(), doc.id).toEntity())
            .toList());
  }
}
