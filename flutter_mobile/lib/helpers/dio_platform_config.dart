import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Conditional import: BrowserHttpClientAdapter is web-only.
import 'dio_platform_config_stub.dart'
    if (dart.library.html) 'dio_platform_config_web.dart' as platform;

/// Platform auth headers + cookie credentials for secure web refresh tokens.
void configureDioForAuth(Dio dio) {
  if (kIsWeb) {
    dio.options.headers['X-Auth-Storage'] = 'cookie';
    dio.options.headers['X-Client-Platform'] = 'web';
    platform.enableWebCredentials(dio);
  } else {
    dio.options.headers['X-Auth-Storage'] = 'body';
    dio.options.headers['X-Client-Platform'] = 'mobile';
  }
}
