import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository;
  List<Category> _categories = [];
  StreamSubscription? _subscription;

  List<Category> get categories => _categories;

  CategoryProvider({CategoryRepository? repository})
      : _repository = repository ?? CategoryRepositoryImpl() {
    _fetchCategories();
  }

  void _fetchCategories() {
    _subscription = _repository.watchCategories().listen(
      (categories) {
        _categories = categories;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('CategoryProvider stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
