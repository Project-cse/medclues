import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'service_providers.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.watch(notificationServiceProvider).fetchAll();
});

final notificationsReadProvider = StateProvider<Set<String>>((_) => {});

/// Unread count for the home notification bell badge.
final unreadNotificationsCountProvider = Provider<AsyncValue<int>>((ref) {
  final list = ref.watch(notificationsProvider);
  final localRead = ref.watch(notificationsReadProvider);
  return list.whenData(
    (items) => items
        .where((n) => !n.read && !localRead.contains(n.id))
        .length,
  );
});