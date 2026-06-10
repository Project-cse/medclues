import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/storage_helper.dart';
import '../helpers/token_helper.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import '../utils/app_exception.dart';
import 'service_providers.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, error: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(AuthState.loading()) {
    checkAuth();
  }

  final Ref _ref;

  Future<void> checkAuth() async {
    state = AuthState.loading();
    final repo = _ref.read(authRepositoryProvider);
    var token = await repo.getToken();
    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }
    if (TokenHelper.isExpired(token)) {
      final refreshed = await repo.tryRefreshSession();
      if (!refreshed) {
        await repo.logout();
        state = AuthState.unauthenticated();
        return;
      }
      token = await repo.getToken();
    }
    final activeToken = token;
    if (activeToken == null || activeToken.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }
    _ref.read(apiServiceProvider).setMemoryToken(activeToken);
    final user = await repo.tryRestoreSession();
    if (user == null) {
      state = AuthState.unauthenticated();
    } else {
      state = AuthState.authenticated(user);
      await _afterAuth();
    }
  }

  /// Returns true on success. Throws [AppException] or [Exception] on failure.
  Future<bool> login(String email, String password) async {
    final previous = state;
    try {
      final user = await _ref.read(authRepositoryProvider).login(email, password);
      await _ref.read(storageHelperProvider).clearPendingNewUser(user.id);
      state = AuthState.authenticated(user);
      await _afterAuth();
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString().replaceFirst('Exception: ', '');
      state = previous.status == AuthStatus.authenticated
          ? previous
          : AuthState.error(msg);
      rethrow;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? gender,
    String? dob,
  }) async {
    final previous = state;
    try {
      final user = await _ref.read(authRepositoryProvider).signup(
            name: name,
            email: email,
            phone: phone,
            password: password,
            gender: gender,
            dob: dob,
          );
      await _ref.read(storageHelperProvider).markPendingNewUser(user.id);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString().replaceFirst('Exception: ', '');
      state = previous.status == AuthStatus.authenticated
          ? previous
          : AuthState.error(msg);
      rethrow;
    }
  }

  Future<bool> loginWithGoogle() async {
    final previous = state;
    try {
      final result = await _ref.read(authRepositoryProvider).loginWithGoogle();
      final storage = _ref.read(storageHelperProvider);
      if (result.isNewUser) {
        await storage.markPendingNewUser(result.user.id);
      } else {
        await storage.clearPendingNewUser(result.user.id);
      }
      state = AuthState.authenticated(result.user);
      await _afterAuth();
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString().replaceFirst('Exception: ', '');
      state = previous.status == AuthStatus.authenticated
          ? previous
          : AuthState.error(msg);
      rethrow;
    }
  }

  Future<void> _afterAuth() async {
    await PushNotificationService.instance.init();
    await PushNotificationService.instance.syncTokenWithBackend();
  }

  Future<void> logout() async {
    final userId = state.user?.id;
    await PushNotificationService.instance.unregisterToken();
    await _ref.read(authRepositoryProvider).logout();
    if (userId != null && userId.isNotEmpty) {
      await _ref.read(storageHelperProvider).clearPendingNewUser(userId);
    }
    _ref.read(apiServiceProvider).setMemoryToken(null);
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));
