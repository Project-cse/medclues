import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
import '../helpers/dio_platform_config.dart';
import '../helpers/storage_helper.dart';
import '../utils/app_exception.dart';

typedef OnUnauthorized = Future<void> Function();

class ApiService {
  ApiService(this._dio, this._storage, {this.onUnauthorized});

  final Dio _dio;
  final StorageHelper _storage;
  OnUnauthorized? onUnauthorized;

  void bindUnauthorized(OnUnauthorized callback) {
    onUnauthorized = callback;
  }

  /// Set immediately after login before async secure-storage write completes.
  String? _memoryToken;
  Future<void>? _refreshFuture;

  Dio get dio => _dio;

  void setMemoryToken(String? token) => _memoryToken = token;

  static ApiService create(StorageHelper storage, {OnUnauthorized? onUnauthorized}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    final service = ApiService(dio, storage, onUnauthorized: onUnauthorized);
    configureDioForAuth(dio);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken() ?? service._memoryToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['token'] = token;
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final isRetry = error.requestOptions.extra['_authRetry'] == true;
        final isAuthPath = path.contains('/api/auth/refresh') ||
            path.contains('/api/auth/logout') ||
            path.contains('/api/user/login') ||
            path.contains('/api/user/register') ||
            path.contains('/api/user/social-login');

        if (status == 401 && !isAuthPath && !isRetry) {
          final refreshed = await service._tryRefreshToken();
          if (refreshed) {
            try {
              final opts = error.requestOptions;
              opts.extra['_authRetry'] = true;
              final newToken = await storage.getAccessToken() ?? service._memoryToken;
              if (newToken != null && newToken.isNotEmpty) {
                opts.headers['Authorization'] = 'Bearer $newToken';
                opts.headers['token'] = newToken;
              }
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {
              await service._forceLogout();
              return handler.reject(error);
            }
          }
          await service._forceLogout();
          return handler.reject(error);
        }
        handler.next(error);
      },
    ));

    if (AppConfig.isDebug) {
      dio.interceptors.add(
        PrettyDioLogger(requestHeader: true, requestBody: true, responseBody: true),
      );
    }

    return service;
  }

  Future<void> _forceLogout() async {
    await _storage.clearAll();
    _memoryToken = null;
    await onUnauthorized?.call();
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshFuture != null) {
      try {
        await _refreshFuture;
        return _memoryToken != null && _memoryToken!.isNotEmpty;
      } catch (_) {
        return false;
      }
    }

    _refreshFuture = _performRefresh();
    try {
      await _refreshFuture;
      return _memoryToken != null && _memoryToken!.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _performRefresh() async {
    final Map<String, dynamic> data;
    if (StorageHelper.usesCookieRefresh) {
      data = await refreshTokensViaCookie();
    } else {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw AppException.auth('No refresh token');
      }
      data = await refreshTokens(refreshToken);
    }
    final access = data['token']?.toString();
    if (access == null || access.isEmpty) {
      throw AppException.auth('Refresh failed');
    }
    await _storage.setAccessToken(access);
    final refresh = data['refresh_token']?.toString();
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.setRefreshToken(refresh);
    }
    _memoryToken = access;
  }

  Dio _plainRefreshDio() {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    configureDioForAuth(refreshDio);
    return refreshDio;
  }

  /// Mobile: refresh token sent in body. Web: HttpOnly cookie (not in JS).
  Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    final refreshDio = _plainRefreshDio();
    try {
      final res = await refreshDio.post<Map<String, dynamic>>(
        ApiConfig.authRefresh,
        data: {'refresh_token': refreshToken, 'role': 'patient'},
      );
      return _parseRefreshResponse(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> refreshTokensViaCookie() async {
    final refreshDio = _plainRefreshDio();
    try {
      final res = await refreshDio.post<Map<String, dynamic>>(
        ApiConfig.authRefresh,
        data: {'role': 'patient'},
      );
      return _parseRefreshResponse(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Map<String, dynamic> _parseRefreshResponse(Map<String, dynamic>? data) {
    final payload = data ?? {};
    if (payload['success'] != true && payload['token'] == null) {
      throw AppException.auth(
        payload['message']?.toString() ?? payload['detail']?.toString() ?? 'Refresh failed',
      );
    }
    return payload;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) async {
    try {
      return await _dio.patch<T>(path, data: data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) async {
    try {
      return await _dio.delete<T>(path, data: data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  static AppException mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppException.network(_networkErrorHint());
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg = _messageFromResponse(e.response?.data) ?? e.message;
        if (code == 401) return AppException.auth(msg);
        if (code == 404) {
          return AppException('Not found', type: AppExceptionType.validation, statusCode: 404);
        }
        if (code != null && code >= 500) return AppException.server(msg);
        return AppException(msg ?? 'Request failed', type: AppExceptionType.validation, statusCode: code);
      default:
        return AppException(e.message ?? 'Unknown error', type: AppExceptionType.unknown);
    }
  }

  static String _networkErrorHint() {
    final base = ApiConfig.baseUrl;
    if (kIsWeb) {
      return 'Cannot reach API at $base. Start backend: cd fastapi_back && .\\start.ps1';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'Cannot reach API at $base. '
          'For a physical phone: stop uvicorn and run '
          'python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload '
          '(or .\\start.ps1 in fastapi_back). '
          'Phone and PC must be on the same Wi‑Fi; check API_BASE_URL in assets/config.env matches ipconfig IPv4.';
    }
    return 'Cannot reach API at $base. Start backend: cd fastapi_back && .\\start.ps1';
  }

  static String? _messageFromResponse(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['detail']?.toString();
    }
    return null;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});
