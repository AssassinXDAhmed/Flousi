import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository _repository;
  SendPasswordResetUseCase(this._repository);

  Future<void> call(String email) =>
      _repository.sendPasswordResetEmail(email: email);
}
