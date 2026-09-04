import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/error_reporter.dart';

/// The languages Otelcim ships. Turkish is the default and the fallback for
/// any string not yet translated in the other locales (template-arb-file:
/// app_tr.arb). The non-Turkish locales target the source countries of
/// seasonal tourism labour on the Turkish coast.
const List<Locale> kSupportedAppLocales = [
  Locale('tr'),
  Locale('en'),
  Locale('ru'),
  Locale('de'),
  Locale('ar'),
];

/// Native-name label for each supported locale, for the language picker.
const Map<String, String> kAppLanguageNames = {
  'tr': 'Türkçe',
  'en': 'English',
  'ru': 'Русский',
  'de': 'Deutsch',
  'ar': 'العربية',
};

const String _localePrefsKey = 'app_locale';

bool _isSupported(String languageCode) =>
    kSupportedAppLocales.any((l) => l.languageCode == languageCode);

/// Holds the user's chosen app language. On first run (no saved choice) it
/// follows the device language when that is one Otelcim ships, otherwise
/// Turkish. An explicit pick in the profile settings overrides and is
/// persisted. [MaterialApp.locale] reads this.
class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(_deviceDefaultLocale()) {
    unawaited(_load());
  }

  static Locale _deviceDefaultLocale() {
    final device = PlatformDispatcher.instance.locale.languageCode;
    return _isSupported(device) ? Locale(device) : const Locale('tr');
  }

  Future<void> _load() async {
    try {
      final code = (await SharedPreferences.getInstance())
          .getString(_localePrefsKey);
      if (code != null && _isSupported(code)) {
        state = Locale(code);
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'LocaleController._load');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) return;
    state = Locale(locale.languageCode);
    try {
      await (await SharedPreferences.getInstance())
          .setString(_localePrefsKey, locale.languageCode);
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'LocaleController.setLocale');
    }
  }
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) => LocaleController());
