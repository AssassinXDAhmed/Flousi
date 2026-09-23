import '../repositories/biometric_repository.dart';

class DisableBiometricUseCase {
  final BiometricRepository _repository;
  DisableBiometricUseCase(this._repository);

  Future<void> call() => _repository.disable();
}
