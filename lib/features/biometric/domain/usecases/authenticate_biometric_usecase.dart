import '../repositories/biometric_repository.dart';

class AuthenticateBiometricUseCase {
  final BiometricRepository _repository;
  AuthenticateBiometricUseCase(this._repository);

  Future<bool> call() => _repository.authenticate();
}
