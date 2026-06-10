import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class TelegramLinkException implements Exception {
  TelegramLinkException(this.message, {this.isNotFound = false});

  final String message;
  final bool isNotFound;

  @override
  String toString() => message;
}

class TelegramLinkInfo {
  const TelegramLinkInfo({
    required this.linked,
    this.deepLink,
    this.botUsername,
    this.telegramUsername,
    this.code,
  });

  final bool linked;
  final String? deepLink;
  final String? botUsername;
  final String? telegramUsername;
  final String? code;

  factory TelegramLinkInfo.fromJson(Map<String, dynamic> json) {
    return TelegramLinkInfo(
      linked: json['linked'] == true,
      deepLink: json['deepLink']?.toString(),
      botUsername: json['botUsername']?.toString(),
      telegramUsername: json['telegramUsername']?.toString(),
      code: json['code']?.toString(),
    );
  }
}

class TelegramLinkService {
  TelegramLinkService(this._api);

  final ApiService _api;

  Future<TelegramLinkInfo> fetchStatus() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiConfig.userTelegramStatus);
      return TelegramLinkInfo.fromJson(res.data ?? {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return TelegramLinkInfo(linked: false, botUsername: ApiConfig.telegramBotUsername);
      }
      rethrow;
    }
  }

  Future<TelegramLinkInfo> createLinkCode() async {
    try {
      final res = await _api.post<Map<String, dynamic>>(ApiConfig.userTelegramLinkCode);
      final info = TelegramLinkInfo.fromJson(res.data ?? {});
      if (info.deepLink != null && info.deepLink!.isNotEmpty) return info;
      final bot = info.botUsername ?? ApiConfig.telegramBotUsername;
      final code = info.code;
      if (bot.isNotEmpty && code != null && code.isNotEmpty) {
        return TelegramLinkInfo(
          linked: info.linked,
          deepLink: 'https://t.me/$bot?start=link_$code',
          botUsername: bot,
          telegramUsername: info.telegramUsername,
          code: code,
        );
      }
      return info;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw TelegramLinkException(
          'Telegram linking API is not available on this server yet.',
          isNotFound: true,
        );
      }
      rethrow;
    }
  }
}
