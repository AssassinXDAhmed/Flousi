import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_remote_data_source.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtRemoteDataSource _dataSource;
  DebtRepositoryImpl({DebtRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? DebtRemoteDataSource();

  @override
  String generateId() => _dataSource.generateId();

  @override
  Stream<List<Debt>> watchDebts(String userId) => _dataSource.watchByUid(userId);

  @override
  Future<void> addDebt(Debt debt) => _dataSource.add(debt);

  @override
  Future<void> togglePaidStatus(Debt debt) =>
      _dataSource.updatePaidStatus(debt.id, !debt.isPaid);

  @override
  Future<void> deleteDebt(String id) => _dataSource.delete(id);
}
