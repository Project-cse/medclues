import '../config/api_config.dart';

class IntegrationService {
  IntegrationService._();

  static bool get hasAgoraConfig => ApiConfig.agoraAppId.isNotEmpty;
  static bool get hasTelegramConfig => ApiConfig.telegramBotToken.isNotEmpty;
}
