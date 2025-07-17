import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../error/error_handler.dart';
import '../storage/local_storage_service.dart';

/// A class that provides localization for the app
class AppLocalization {
  final LocalStorageService _storageService;
  final ErrorHandler _errorHandler;
  final LocaleNotifier _localeNotifier;

  /// Map of supported locales
  final Map<String, Locale> supportedLocales = {
    'en': const Locale('en', 'US'),
    'es': const Locale('es', 'ES'),
    'fr': const Locale('fr', 'FR'),
    'zh': const Locale('zh', 'CN'),
    'ar': const Locale('ar', 'SA'),
  };

  /// Storage key for locale
  static const String _localeKey = 'app_locale';

  /// Default locale
  static const Locale _defaultLocale = Locale('en', 'US');

  /// Map of translations
  final Map<String, Map<String, String>> _localizedValues = {};

  /// Creates a new instance of [AppLocalization]
  AppLocalization({
    required LocalStorageService storageService,
    required ErrorHandler errorHandler,
  })  : _storageService = storageService,
        _errorHandler = errorHandler,
        _localeNotifier = LocaleNotifier(_defaultLocale);

  /// Initializes the localization
  Future<void> init() async {
    try {
      // Load the saved locale from storage
      final savedLocale = _storageService.getString(_localeKey);
      if (savedLocale != null && supportedLocales.containsKey(savedLocale)) {
        _localeNotifier.update(supportedLocales[savedLocale]!);
      } else {
        // Load system locale if available
        final systemLocale = ui.PlatformDispatcher.instance.locale;
        final languageCode = systemLocale.languageCode;

        if (supportedLocales.containsKey(languageCode)) {
          _localeNotifier.update(supportedLocales[languageCode]!);
          await _storageService.saveString(_localeKey, languageCode);
        } else {
          _localeNotifier.update(_defaultLocale);
          await _storageService.saveString(
              _localeKey, _defaultLocale.languageCode);
        }
      }

      // Load translations for all supported locales
      await _loadAllTranslations();
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        AppException.localization(
          message: 'Failed to initialize localization',
          cause: e,
          stackTrace: stackTrace,
        ),
      );
      // Set default locale as fallback
      _localeNotifier.update(_defaultLocale);
    }
  }

  /// Loads all translations for supported locales
  Future<void> _loadAllTranslations() async {
    for (final locale in supportedLocales.values) {
      await _loadTranslationsForLocale(locale);
    }
  }

  /// Loads translations for a specific locale
  Future<void> _loadTranslationsForLocale(Locale locale) async {
    try {
      final languageCode = locale.languageCode;
      final jsonString = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedValues[languageCode] =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        AppException.localization(
          message:
              'Failed to load translations for locale: ${locale.languageCode}',
          cause: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Gets a translated string for the given key
  String translate(String key) {
    try {
      final languageCode = _localeNotifier.state.languageCode;
      if (_localizedValues.containsKey(languageCode) &&
          _localizedValues[languageCode]!.containsKey(key)) {
        return _localizedValues[languageCode]![key]!;
      }

      // Fallback to default locale if key not found in current locale
      if (_localizedValues.containsKey(_defaultLocale.languageCode) &&
          _localizedValues[_defaultLocale.languageCode]!.containsKey(key)) {
        return _localizedValues[_defaultLocale.languageCode]![key]!;
      }

      // If still not found, return the key itself
      return key;
    } catch (e) {
      return key;
    }
  }

  /// Gets the current locale
  Locale get locale => _localeNotifier.state;

  /// Provider for locale
  StateNotifierProvider<LocaleNotifier, Locale> get localeProvider =>
      StateNotifierProvider<LocaleNotifier, Locale>((ref) => _localeNotifier);

  /// Sets the locale
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.values.contains(locale)) {
      throw AppException.localization(
        message: 'Unsupported locale: ${locale.languageCode}',
      );
    }

    try {
      await _storageService.saveString(_localeKey, locale.languageCode);
      _localeNotifier.update(locale);
      
      // Ensure translations are loaded for this locale
      await _loadTranslationsForLocale(locale);
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        AppException.localization(
          message: 'Failed to set locale: ${locale.languageCode}',
          cause: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Gets a list of supported locales
  List<Locale> get supportedLocalesList => supportedLocales.values.toList();

  /// Function to create a localization delegate
  LocalizationsDelegate<AppLocalizationDelegate> createDelegate() =>
      AppLocalizationDelegate(this);
}

/// App localization delegate for flutter localization system
class AppLocalizationDelegate
    extends LocalizationsDelegate<AppLocalizationDelegate> {
  final AppLocalization _localization;

  /// Creates a new instance of [AppLocalizationDelegate]
  AppLocalizationDelegate(this._localization);

  @override
  bool isSupported(Locale locale) {
    return _localization.supportedLocales.values.contains(locale);
  }

  @override
  Future<AppLocalizationDelegate> load(Locale locale) async {
    return this;
  }

  @override
  bool shouldReload(
      covariant LocalizationsDelegate<AppLocalizationDelegate> old) {
    return false;
  }

  /// Gets a translated string for the given key
  String translate(String key) => _localization.translate(key);
}

/// Extension to easily access translations
extension TranslateX on String {
  /// Gets a translated string for this key
  String tr(BuildContext context) {
    final delegate = Localizations.of<AppLocalizationDelegate>(
      context,
      AppLocalizationDelegate,
    );
    if (delegate != null) {
      return delegate.translate(this);
    }
    return this;
  }
}

/// Extension to easily access translations from a build context
extension LocalizationX on BuildContext {
  /// Gets a translated string for the given key
  String tr(String key) {
    final delegate = Localizations.of<AppLocalizationDelegate>(
      this,
      AppLocalizationDelegate,
    );
    if (delegate != null) {
      return delegate.translate(key);
    }
    return key;
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.state);

  void update(Locale locale) => state = locale;
}
