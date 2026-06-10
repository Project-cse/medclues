import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/storage_helper.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceX on AppThemePreference {
  String get storageValue => name;

  static AppThemePreference fromStorage(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.system;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }
}

class ThemeModeNotifier extends StateNotifier<AppThemePreference> {
  ThemeModeNotifier(this._ref, AppThemePreference initial) : super(initial);

  final Ref _ref;

  ThemeMode get materialThemeMode => state.themeMode;

  Future<void> setPreference(AppThemePreference preference) async {
    state = preference;
    await _ref.read(storageHelperProvider).setThemePreference(preference.storageValue);
    // Keep legacy bool in sync for any old readers.
    await _ref.read(storageHelperProvider).setDarkMode(preference == AppThemePreference.dark);
  }

  Future<void> toggle() async {
    final next = state == AppThemePreference.dark
        ? AppThemePreference.light
        : AppThemePreference.dark;
    await setPreference(next);
  }
}

final themePreferenceProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemePreference>((ref) {
  final stored = ref.read(storageHelperProvider).getThemePreference();
  return ThemeModeNotifier(ref, AppThemePreferenceX.fromStorage(stored));
});

/// Resolved [ThemeMode] for [MaterialApp.themeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themePreferenceProvider).themeMode;
});
