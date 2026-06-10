import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/storage_helper.dart';

/// Supported app locales.
class AppLocales {
  AppLocales._();

  static const en = Locale('en');
  static const te = Locale('te');
  static const hi = Locale('hi');

  static const all = [en, te, hi];

  static Locale fromCode(String? code) {
    switch (code) {
      case 'te':
        return te;
      case 'hi':
        return hi;
      default:
        return en;
    }
  }

  static String codeFromLocale(Locale locale) => locale.languageCode;
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._ref, Locale initial) : super(initial);

  final Ref _ref;

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    state = locale;
    await _ref.read(storageHelperProvider).setLocale(locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final stored = ref.read(storageHelperProvider).getLocale();
  return LocaleNotifier(ref, AppLocales.fromCode(stored));
});
