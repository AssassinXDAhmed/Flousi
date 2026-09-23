abstract class BiometricRepository {
  Future<bool> isAvailable();
  Future<bool> isEnabled();
  Future<bool> authenticate();
  Future<void> enable();
  Future<void> disable();
}
