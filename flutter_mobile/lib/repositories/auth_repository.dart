import '../helpers/storage_helper.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';
import '../services/apple_auth_service.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../utils/app_exception.dart';

class AuthRepository {
  AuthRepository(this._auth, this._storage, [GoogleAuthService? googleAuth, AppleAuthService? appleAuth])
      : _googleAuth = googleAuth ?? GoogleAuthService(),
        _appleAuth = appleAuth ?? AppleAuthService();

  final AuthService _auth;
  final StorageHelper _storage;
  final GoogleAuthService _googleAuth;
  final AppleAuthService _appleAuth;

  Future<void> _persistTokens(AuthTokens tokens, {bool remember = true, String? email}) async {
    await _storage.setAccessToken(tokens.accessToken);
    if (tokens.refreshToken.isNotEmpty) {
      await _storage.setRefreshToken(tokens.refreshToken);
    }
    if (remember && email != null) {
      await _storage.saveUserJson('{"email":"$email"}');
    }
  }

  Future<UserModel> login(String email, String password, {bool remember = true}) async {
    final tokens = await _auth.login(email, password);
    await _persistTokens(tokens);
    UserModel user;
    try {
      user = await _auth.fetchProfile();
    } on AppException catch (e) {
      if (e.type != AppExceptionType.network) rethrow;
      user = UserModel(
        id: '',
        name: email.split('@').first,
        email: email,
        phone: '',
      );
    }
    if (remember) {
      await _storage.saveUserJson('{"email":"${user.email}"}');
    }
    return user;
  }

  Future<UserModel> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? gender,
    String? dob,
    String? bloodGroup,
    String? phoneIdToken,
  }) async {
    final tokens = await _auth.signup(
      name: name,
      email: email,
      phone: phone,
      password: password,
      gender: gender,
      dob: dob,
      bloodGroup: bloodGroup,
      phoneIdToken: phoneIdToken,
    );
    await _persistTokens(tokens);
    return _auth.fetchProfile();
  }

  Future<({UserModel user, bool isNewUser})> loginWithGoogle() async {
    final firebaseUser = await _googleAuth.signInWithGoogle();
    final email = firebaseUser.email!;
    // Firebase ID token lets the backend verify this sign-in server-side.
    String? idToken;
    try {
      idToken = await firebaseUser.getIdToken();
    } catch (_) {
      idToken = null;
    }
    final tokens = await _auth.socialLogin(
      email: email,
      name: firebaseUser.displayName ?? email.split('@').first,
      photoURL: firebaseUser.photoURL,
      provider: 'google',
      uid: firebaseUser.uid,
      idToken: idToken,
    );
    await _persistTokens(tokens);
    UserModel user;
    try {
      user = await _auth.fetchProfile();
    } on AppException catch (e) {
      if (e.type != AppExceptionType.network) rethrow;
      user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? email.split('@').first,
        email: email,
        phone: '',
        imageUrl: firebaseUser.photoURL,
      );
    }
    await _storage.saveUserJson('{"email":"${user.email}"}');
    return (user: user, isNewUser: tokens.isNewUser);
  }

  Future<({UserModel user, bool isNewUser})> loginWithApple() async {
    final firebaseUser = await _appleAuth.signInWithApple();
    final email = firebaseUser.email ?? '${firebaseUser.uid}@privaterelay.appleid.com';
    String? idToken;
    try {
      idToken = await firebaseUser.getIdToken();
    } catch (_) {
      idToken = null;
    }
    final tokens = await _auth.socialLogin(
      email: email,
      name: firebaseUser.displayName ?? email.split('@').first,
      photoURL: firebaseUser.photoURL,
      provider: 'apple',
      uid: firebaseUser.uid,
      idToken: idToken,
    );
    await _persistTokens(tokens);
    UserModel user;
    try {
      user = await _auth.fetchProfile();
    } on AppException catch (e) {
      if (e.type != AppExceptionType.network) rethrow;
      user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? email.split('@').first,
        email: email,
        phone: '',
        imageUrl: firebaseUser.photoURL,
      );
    }
    await _storage.saveUserJson('{"email":"${user.email}"}');
    return (user: user, isNewUser: tokens.isNewUser);
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.getRefreshToken();
      await _auth.logout(refreshToken: refresh);
    } catch (_) {
      /* revoke best-effort */
    }
    try {
      await _googleAuth.signOut();
    } catch (_) {
      /* optional */
    }
    await _storage.clearAll();
  }

  Future<String?> getToken() => _storage.getAccessToken();

  Future<bool> tryRefreshSession() async {
    if (!StorageHelper.usesCookieRefresh) {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) return false;
    }
    try {
      final refresh = await _storage.getRefreshToken() ?? '';
      final tokens = await _auth.refreshAccessToken(refresh);
      await _storage.setAccessToken(tokens.accessToken);
      if (tokens.refreshToken.isNotEmpty) {
        await _storage.setRefreshToken(tokens.refreshToken);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> tryRestoreSession() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _auth.fetchProfile();
    } catch (_) {
      final refreshed = await tryRefreshSession();
      if (!refreshed) {
        await _storage.clearAll();
        return null;
      }
      try {
        return await _auth.fetchProfile();
      } catch (_) {
        await _storage.clearAll();
        return null;
      }
    }
  }
}
