import '../repositories/biometric_repository.dart';

class IsBiometricEnabledUseCase {
  final BiometricRepository _repository;
  IsBiometricEnabledUseCase(this._repository);

  Future<bool> call() => _repository.isEnabled();
}
