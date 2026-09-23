import '../repositories/biometric_repository.dart';

class EnableBiometricUseCase {
  final BiometricRepository _repository;
  EnableBiometricUseCase(this._repository);

  Future<void> call() => _repository.enable();
}
