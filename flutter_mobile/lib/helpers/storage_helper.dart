import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  StorageHelper(this._secure, this._prefs);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = '@pms/user';
  static const String recentSearchesKey = '@pms/recent_searches';
  static const String darkModeKey = '@pms/dark_mode';
  static const String themeModeKey = '@pms/theme_mode';
  static const String localeKey = '@pms/app_locale';
  static const String permissionsSetupKey = '@pms/permissions_setup_done';
  static String _tutorialKey(String userId, String suffix) => '@pms/tutorial/$suffix/$userId';

  /// Web uses HttpOnly cookies for refresh tokens (not readable by JavaScript).
  static bool get usesCookieRefresh => kIsWeb;

  bool get _usePrefsForAccessOnWeb => kIsWeb;

  bool getDarkMode() => _prefs.getBool(darkModeKey) ?? false;

  Future<void> setDarkMode(bool value) => _prefs.setBool(darkModeKey, value);

  /// `system` | `light` | `dark` — defaults to system (follows phone setting).
  String getThemePreference() {
    final stored = _prefs.getString(themeModeKey);
    if (stored != null) return stored;
    // Migrate legacy bool toggle.
    if (_prefs.containsKey(darkModeKey)) {
      return getDarkMode() ? 'dark' : 'light';
    }
    return 'system';
  }

  Future<void> setThemePreference(String value) =>
      _prefs.setString(themeModeKey, value);

  /// `en` | `te` | `hi` — defaults to English.
  String getLocale() => _prefs.getString(localeKey) ?? 'en';

  Future<void> setLocale(String languageCode) =>
      _prefs.setString(localeKey, languageCode);

  bool isPermissionsSetupDone() => _prefs.getBool(permissionsSetupKey) ?? false;

  Future<void> setPermissionsSetupDone(bool value) =>
      _prefs.setBool(permissionsSetupKey, value);

  Future<String?> getAccessToken() async {
    if (_usePrefsForAccessOnWeb) return _prefs.getString(accessTokenKey);
    try {
      return await _secure.read(key: accessTokenKey);
    } catch (_) {
      return _prefs.getString(accessTokenKey);
    }
  }

  Future<void> setAccessToken(String token) async {
    if (_usePrefsForAccessOnWeb) {
      await _prefs.setString(accessTokenKey, token);
      return;
    }
    try {
      await _secure.write(key: accessTokenKey, value: token);
    } catch (_) {
      await _prefs.setString(accessTokenKey, token);
    }
  }

  Future<String?> getRefreshToken() async {
    if (usesCookieRefresh) return null;
    try {
      return await _secure.read(key: refreshTokenKey);
    } catch (_) {
      return _prefs.getString(refreshTokenKey);
    }
  }

  Future<void> setRefreshToken(String token) async {
    if (usesCookieRefresh) return;
    try {
      await _secure.write(key: refreshTokenKey, value: token);
    } catch (_) {
      await _prefs.setString(refreshTokenKey, token);
    }
  }

  Future<void> clearTokens() async {
    if (_usePrefsForAccessOnWeb) {
      await _prefs.remove(accessTokenKey);
    }
    if (!usesCookieRefresh) {
      try {
        await _secure.delete(key: accessTokenKey);
        await _secure.delete(key: refreshTokenKey);
      } catch (_) {
        /* ignore */
      }
      await _prefs.remove(accessTokenKey);
      await _prefs.remove(refreshTokenKey);
    } else {
      await _prefs.remove(accessTokenKey);
      // Legacy web refresh keys from older builds
      await _prefs.remove(refreshTokenKey);
    }
  }

  Future<void> saveUserJson(String json) => _prefs.setString(userKey, json);

  String? getUserJson() => _prefs.getString(userKey);

  Future<void> clearUser() => _prefs.remove(userKey);

  List<String> getRecentSearches() =>
      _prefs.getStringList(recentSearchesKey) ?? [];

  Future<void> addRecentSearch(String query) async {
    final list = getRecentSearches().where((e) => e != query).toList();
    list.insert(0, query);
    await _prefs.setStringList(recentSearchesKey, list.take(10).toList());
  }

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
  }

  /// Fresh signup or first-time Google registration for this account.
  bool isPendingNewUser(String userId) =>
      userId.isNotEmpty && (_prefs.getBool(_tutorialKey(userId, 'pending')) ?? false);

  Future<void> markPendingNewUser(String userId) =>
      _prefs.setBool(_tutorialKey(userId, 'pending'), true);

  Future<void> clearPendingNewUser(String userId) =>
      _prefs.remove(_tutorialKey(userId, 'pending'));

  bool isOnboardingCompletedFor(String userId) =>
      userId.isNotEmpty && (_prefs.getBool(_tutorialKey(userId, 'onboarding')) ?? false);

  Future<void> setOnboardingCompletedFor(String userId, bool value) =>
      _prefs.setBool(_tutorialKey(userId, 'onboarding'), value);

  Future<void> resetOnboardingFor(String userId) =>
      _prefs.remove(_tutorialKey(userId, 'onboarding'));

  bool isDoctorProfileTutorialSeenFor(String userId) =>
      userId.isNotEmpty && (_prefs.getBool(_tutorialKey(userId, 'doctor')) ?? false);

  Future<void> setDoctorProfileTutorialSeenFor(String userId, bool value) =>
      _prefs.setBool(_tutorialKey(userId, 'doctor'), value);
}

final storageHelperProvider = Provider<StorageHelper>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});
