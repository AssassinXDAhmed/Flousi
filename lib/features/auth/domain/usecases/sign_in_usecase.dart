import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;
  SignInUseCase(this._repository);

  Future<void> call({required String email, required String password}) =>
      _repository.signInWithEmailPassword(email: email, password: password);
}
