import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/telegram_link_service.dart';
import 'service_providers.dart';

final telegramLinkStatusProvider = FutureProvider<TelegramLinkInfo>((ref) async {
  return ref.read(telegramLinkServiceProvider).fetchStatus();
});
