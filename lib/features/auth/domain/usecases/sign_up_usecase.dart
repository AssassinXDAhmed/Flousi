import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  SignUpUseCase(this._repository);

  Future<void> call({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _repository.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
}
