import '../../domain/entities/category.dart';

/// Abstract contract for the categories data source.
abstract class CategoryRepository {
  Stream<List<Category>> watchCategories();
}
