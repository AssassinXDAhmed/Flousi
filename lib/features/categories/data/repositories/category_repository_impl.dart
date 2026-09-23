import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _dataSource;
  CategoryRepositoryImpl({CategoryRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? CategoryRemoteDataSource();

  @override
  Stream<List<Category>> watchCategories() => _dataSource.watchAll();
}
