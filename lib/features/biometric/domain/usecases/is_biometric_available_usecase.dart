import '../repositories/biometric_repository.dart';

class IsBiometricAvailableUseCase {
  final BiometricRepository _repository;
  IsBiometricAvailableUseCase(this._repository);

  Future<bool> call() => _repository.isAvailable();
}
