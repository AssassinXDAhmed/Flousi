import '../../data/repositories/biometric_repository_impl.dart';
import '../../domain/repositories/biometric_repository.dart';
import '../../domain/usecases/authenticate_biometric_usecase.dart';
import '../../domain/usecases/disable_biometric_usecase.dart';
import '../../domain/usecases/enable_biometric_usecase.dart';
import '../../domain/usecases/is_biometric_available_usecase.dart';
import '../../domain/usecases/is_biometric_enabled_usecase.dart';

/// App-level singleton facade over the biometric use cases.
///
/// Preserves the legacy in-memory [skipNextSignIn] flag that is shared across
/// the root AuthWrapper, the profile logout action and the biometric lock
/// screen, so the sign-in flow timing stays identical to the original.
class BiometricService {
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;
  BiometricService._()
      : _repository = BiometricRepositoryImpl() {
    _isAvailableUseCase = IsBiometricAvailableUseCase(_repository);
    _isEnabledUseCase = IsBiometricEnabledUseCase(_repository);
    _authenticateUseCase = AuthenticateBiometricUseCase(_repository);
    _enableUseCase = EnableBiometricUseCase(_repository);
    _disableUseCase = DisableBiometricUseCase(_repository);
  }

  final BiometricRepository _repository;
  late final IsBiometricAvailableUseCase _isAvailableUseCase;
  late final IsBiometricEnabledUseCase _isEnabledUseCase;
  late final AuthenticateBiometricUseCase _authenticateUseCase;
  late final EnableBiometricUseCase _enableUseCase;
  late final DisableBiometricUseCase _disableUseCase;

  /// In-memory flag: when true, the next successful sign-in skips the
  /// biometric gate (the user authenticated via password). Cleared after
  /// that sign-in.
  bool skipNextSignIn = false;

  Future<bool> isAvailable() => _isAvailableUseCase.call();
  Future<bool> isEnabled() => _isEnabledUseCase.call();
  Future<bool> authenticate() => _authenticateUseCase.call();
  Future<void> enable() => _enableUseCase.call();
  Future<void> disable() => _disableUseCase.call();
}
