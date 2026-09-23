import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/biometric/domain/services/biometric_service.dart';
import 'features/biometric/presentation/screens/biometric_lock_screen.dart';
import 'features/categories/presentation/providers/category_provider.dart';
import 'features/debts/presentation/providers/debt_provider.dart';
import 'features/home/presentation/screens/main_screen.dart';
import 'features/subscriptions/presentation/providers/subscription_provider.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Restore the user's saved language before the first frame so screens
  // like the biometric lock screen never flash the wrong language.
  final localeProvider = LocaleProvider();
  await localeProvider.loadFromStorage();
  runApp(LibyanExpenseHub(localeProvider: localeProvider));
}

class LibyanExpenseHub extends StatelessWidget {
  final LocaleProvider localeProvider;

  const LibyanExpenseHub({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider.value(value: localeProvider)
      ],
      child: Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return MaterialApp(
              title: 'Flousi',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              locale: localeProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''), // English
                Locale('ar', ''), // Arabic
              ],

              // OPTIONAL: UNCOMMENT THIS IF YOU WANT TO FORCE LTR LAYOUT FOR ARABIC
              // builder: (context, child) {
                //return Directionality(
                  //textDirection: TextDirection.ltr,
                  //child: child!,
                //);
               //},

              home: const AuthWrapper(),
            );
          }
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

enum _AuthGateState { loading, locked, unlocked, signedOut }

class _AuthWrapperState extends State<AuthWrapper> {
  final BiometricService _biometricService = BiometricService();
  final AuthRepository _authRepository = AuthRepositoryImpl();
  dynamic _lastUser;
  _AuthGateState _gate = _AuthGateState.loading;
  String? _fallbackEmail;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _splash();
        }

        final user = snapshot.data;

        // React only when the authenticated user actually changes.
        if (user?.uid != _lastUser?.uid) {
          _lastUser = user;
          if (user != null) {
            if (_biometricService.skipNextSignIn) {
              // Password path (manual logout or biometric fallback): skip the
              // gate and clear the flag so future app opens resume normal
              // biometric behavior.
              _biometricService.skipNextSignIn = false;
              _gate = _AuthGateState.unlocked;
            } else {
              // Show splash while we check whether biometric is enabled, so
              // MainScreen never renders before the gate resolves.
              _gate = _AuthGateState.loading;
              _evaluateBiometricGate();
            }
          } else {
            _gate = _AuthGateState.signedOut;
          }
        }

        if (user == null) {
          return LoginScreen(initialEmail: _fallbackEmail);
        }

        switch (_gate) {
          case _AuthGateState.loading:
            return _splash();
          case _AuthGateState.locked:
            // Capture the email so the password fallback can pre-fill the
            // login screen after sign-out.
            _fallbackEmail = user.email;
            return BiometricLockScreen(
              onUnlocked: () => setState(() => _gate = _AuthGateState.unlocked),
              onUsePassword: _handleUsePassword,
            );
          case _AuthGateState.unlocked:
            _fallbackEmail = null;
            return const MainScreen();
          case _AuthGateState.signedOut:
            return LoginScreen(initialEmail: _fallbackEmail);
        }
      },
    );
  }

  Future<void> _evaluateBiometricGate() async {
    final enabled = await _biometricService.isEnabled();
    if (mounted) {
      setState(() => _gate = enabled ? _AuthGateState.locked : _AuthGateState.unlocked);
    }
  }

  // "Use password instead" from the biometric lock: arm the skip flag FIRST so
  // it survives the sign-out emission, then sign out to reveal the login screen.
  Future<void> _handleUsePassword() async {
    _biometricService.skipNextSignIn = true;
    _gate = _AuthGateState.signedOut;
    await _authRepository.signOut();
    if (mounted) setState(() {});
  }

  Widget _splash() {
    return const Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.brandGreen),
      ),
    );
  }
}
