import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app locale and persists the user's choice to
/// SharedPreferences so it survives app restarts (e.g. after enabling
/// biometric login, which restarts the auth flow / app session).
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale';
  static const Locale _defaultLocale = Locale('en', '');

  LocaleProvider();

  Locale _locale = _defaultLocale;

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  /// Reads the saved locale from SharedPreferences. Call once at startup,
  /// before `runApp`, so the first frame already uses the user's language.
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    final Locale loaded;
    if (code == 'ar') {
      loaded = const Locale('ar', '');
    } else if (code == 'en') {
      loaded = const Locale('en', '');
    } else {
      loaded = _defaultLocale;
    }
    if (_locale != loaded) {
      _locale = loaded;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  Future<void> setArabic() => setLocale(const Locale('ar', ''));

  Future<void> setEnglish() => setLocale(const Locale('en', ''));

  void toggleLocale() {
    setLocale(_locale.languageCode == 'en'
        ? const Locale('ar', '')
        : const Locale('en', ''));
  }
}
