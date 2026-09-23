import '../entities/debt.dart';

abstract class DebtRepository {
  String generateId();
  Stream<List<Debt>> watchDebts(String userId);
  Future<void> addDebt(Debt debt);
  Future<void> togglePaidStatus(Debt debt);
  Future<void> deleteDebt(String id);
}
