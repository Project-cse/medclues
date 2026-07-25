import '../config/api_config.dart';
import '../helpers/storage_helper.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class AuthService {
  AuthService(this._api);

  final ApiService _api;

  AuthTokens _parseTokens(Map<String, dynamic> data, String fallbackMessage) {
    assertSuccess(data, fallbackMessage);
    final access = data['token']?.toString();
    final refresh = data['refresh_token']?.toString() ?? '';
    if (access == null || access.isEmpty) throw Exception('No token returned');
    if (!StorageHelper.usesCookieRefresh && refresh.isEmpty) {
      throw Exception('No refresh token returned');
    }
    _api.setMemoryToken(access);
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      isNewUser: data['isNewUser'] == true,
    );
  }

  Future<AuthTokens> login(String email, String password) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userLogin,
      data: {'email': email.trim(), 'password': password},
    );
    return _parseTokens(res.data ?? {}, 'Invalid credentials');
  }

  Future<AuthTokens> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? gender,
    String? dob,
    String? bloodGroup,
    String? phoneIdToken,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userRegister,
      data: {
        'name': name,
        'email': email.trim(),
        'phone': phone,
        'password': password,
        if (gender != null) 'gender': gender,
        if (dob != null) 'dob': dob,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (phoneIdToken != null && phoneIdToken.isNotEmpty) 'phoneIdToken': phoneIdToken,
      },
    );
    return _parseTokens(res.data ?? {}, 'Registration failed');
  }

  /// Sends a 6-digit OTP to verify an email during signup (before the account
  /// exists). Returns a dev OTP when the backend is in debug mode.
  Future<String?> sendSignupEmailOtp(String email) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userSignupSendEmailOtp,
      data: {'email': email.trim()},
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Failed to send verification code');
    return data['dev_otp']?.toString();
  }

  Future<void> verifySignupEmailOtp(String email, String otp) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userSignupVerifyEmailOtp,
      data: {'email': email.trim(), 'otp': otp.trim()},
    );
    assertSuccess(res.data ?? {}, 'Invalid code');
  }

  Future<void> forgotPassword(String email) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.authForgotPassword,
      data: {'email': email.trim(), 'role': 'patient'},
    );
    assertSuccess(res.data ?? {}, 'Failed to send OTP');
  }

  Future<void> verifyOtp(String email, String otp) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.authVerifyOtp,
      data: {'email': email.trim(), 'otp': otp, 'role': 'patient'},
    );
    final data = res.data ?? {};
    if (data['valid'] != true && data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Invalid OTP');
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.authResetPassword,
      data: {
        'email': email.trim(),
        'otp': otp,
        'new_password': newPassword,
        'role': 'patient',
      },
    );
    assertSuccess(res.data ?? {}, 'Reset failed');
  }

  Future<AuthTokens> socialLogin({
    required String email,
    required String name,
    String? photoURL,
    required String provider,
    required String uid,
    String? idToken,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userSocialLogin,
      data: {
        'email': email.trim(),
        'name': name,
        'photoURL': photoURL,
        'provider': provider,
        'uid': uid,
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
      },
    );
    return _parseTokens(res.data ?? {}, 'Google sign-in failed');
  }

  Future<AuthTokens> refreshAccessToken(String refreshToken) async {
    final data = StorageHelper.usesCookieRefresh
        ? await _api.refreshTokensViaCookie()
        : await _api.refreshTokens(refreshToken);
    final access = data['token']?.toString();
    final refresh = data['refresh_token']?.toString() ?? '';
    if (access == null || access.isEmpty) throw Exception('Refresh failed');
    _api.setMemoryToken(access);
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> logout({String? refreshToken}) async {
    final payload = <String, dynamic>{'role': 'patient'};
    if (!StorageHelper.usesCookieRefresh && refreshToken != null && refreshToken.isNotEmpty) {
      payload['refresh_token'] = refreshToken;
    }
    await _api.post<Map<String, dynamic>>(ApiConfig.authLogout, data: payload);
  }

  Future<UserModel> fetchProfile() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.userProfile);
    final data = res.data ?? {};
    assertSuccess(data);
    final user = (data['userData'] ?? data['user']) as Map<String, dynamic>?;
    if (user == null) throw Exception('Profile unavailable');
    return UserModel.fromJson(user);
  }
}
