import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localization service for managing app language
/// Supports English (en_US) and Hebrew (he_IL)
/// Implements singleton pattern
class LocalizationService {
  // Private constructor for singleton
  LocalizationService._();

  // Singleton instance
  static final LocalizationService instance = LocalizationService._();

  // SharedPreferences key
  static const String _localeKey = 'app_locale';

  // Stream controller for locale changes
  final _localeController = StreamController<Locale>.broadcast();

  // Current locale
  Locale _currentLocale = const Locale('en', 'US'); // Default to English

  // Supported locales
  static const Locale englishLocale = Locale('en', 'US');
  static const Locale hebrewLocale = Locale('he', 'IL');

  static const List<Locale> supportedLocales = [
    englishLocale,
    hebrewLocale,
  ];

  /// Get stream of locale changes
  Stream<Locale> get localeStream => _localeController.stream;

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Check if current locale is Hebrew (RTL)
  bool get isRTL => _currentLocale.languageCode == 'he';

  /// Check if current locale is English
  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// Initialize localization service
  /// Loads saved locale from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);

      if (savedLocaleCode != null) {
        // Parse saved locale
        final parts = savedLocaleCode.split('_');
        if (parts.length == 2) {
          _currentLocale = Locale(parts[0], parts[1]);
        }
      }

      // Notify listeners
      _localeController.add(_currentLocale);
    } catch (e) {
      debugPrint('Error initializing LocalizationService: $e');
      // Keep default locale
    }
  }

  /// Set locale
  /// Saves to SharedPreferences and notifies listeners
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      debugPrint('Unsupported locale: $locale');
      return;
    }

    try {
      _currentLocale = locale;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');

      // Notify listeners
      _localeController.add(_currentLocale);
    } catch (e) {
      debugPrint('Error setting locale: $e');
    }
  }

  /// Toggle between English and Hebrew
  Future<void> toggleLocale() async {
    final newLocale = _currentLocale.languageCode == 'en'
        ? hebrewLocale
        : englishLocale;
    await setLocale(newLocale);
  }

  /// Get text direction based on current locale
  TextDirection get textDirection {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Dispose stream controller
  void dispose() {
    _localeController.close();
  }
}
