import 'package:url_launcher/url_launcher.dart';

/// Opens Telegram app when installed, otherwise the t.me web link.
Future<bool> openTelegramLink(String deepLink) async {
  final https = Uri.tryParse(deepLink);
  if (https == null) return false;

  final bot = https.pathSegments.isNotEmpty ? https.pathSegments.first : '';
  final start = https.queryParameters['start'];

  if (bot.isNotEmpty) {
    final tgQuery = StringBuffer('domain=$bot');
    if (start != null && start.isNotEmpty) {
      tgQuery.write('&start=$start');
    }
    final tgUri = Uri.parse('tg://resolve?$tgQuery');
    if (await canLaunchUrl(tgUri)) {
      return launchUrl(tgUri, mode: LaunchMode.externalApplication);
    }
  }

  return launchUrl(https, mode: LaunchMode.externalApplication);
}

Future<bool> openTelegramBot(String botUsername, {String? startPayload}) async {
  final user = botUsername.replaceFirst('@', '').trim();
  if (user.isEmpty) return false;
  final https = startPayload != null && startPayload.isNotEmpty
      ? Uri.parse('https://t.me/$user?start=$startPayload')
      : Uri.parse('https://t.me/$user');
  return openTelegramLink(https.toString());
}

Future<bool> openTelegramStore() async {
  const playStore = 'https://play.google.com/store/apps/details?id=org.telegram.messenger';
  const appStore = 'https://apps.apple.com/app/telegram-messenger/id686449807';
  final play = Uri.parse(playStore);
  if (await canLaunchUrl(play)) {
    return launchUrl(play, mode: LaunchMode.externalApplication);
  }
  return launchUrl(Uri.parse(appStore), mode: LaunchMode.externalApplication);
}
