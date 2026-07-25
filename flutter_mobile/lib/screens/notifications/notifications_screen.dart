import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/theme_context.dart';
import '../../widgets/common/app_empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final read = ref.watch(notificationsReadProvider);
    final cs = context.cs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              final all = notifications.valueOrNull ?? [];
              ref.read(notificationsReadProvider.notifier).state =
                  all.map((n) => n.id).toSet();
              ref.read(notificationServiceProvider).markAllRead();
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: cs.primary),
            ),
          ),
        ],
      ),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) return const AppEmptyState(title: 'No notifications');
          return RefreshIndicator(
            color: AppColors.logoTeal,
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: context.borderColor),
              itemBuilder: (_, i) {
                final n = items[i];
                final isRead = n.read || read.contains(n.id);
                return _NotificationTile(notification: n, read: isRead);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: context.primaryText))),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification, required this.read});

  final NotificationModel notification;
  final bool read;

  bool get _isCancelled =>
      notification.id.startsWith('cancel_') ||
      notification.title.toLowerCase().contains('cancel');
  bool get _isCompleted =>
      notification.id.startsWith('done_') ||
      notification.title.toLowerCase().contains('prescription') ||
      notification.title.toLowerCase().contains('complete');

  IconData get _icon {
    if (_isCancelled) return Icons.cancel_outlined;
    if (_isCompleted) return Icons.check_circle_outline;
    switch (notification.type) {
      case NotificationType.appointment:
        return Icons.event_available_outlined;
      case NotificationType.reminder:
        return Icons.alarm_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _accent(BuildContext context) {
    if (_isCancelled) return const Color(0xFFE11D48);
    if (_isCompleted) return const Color(0xFF16A34A);
    return context.cs.primary;
  }

  void _markRead(WidgetRef ref) {
    ref.read(notificationsReadProvider.notifier).update(
          (s) => {...s, notification.id},
        );
    ref.read(notificationServiceProvider).markRead(notification.id);
  }

  void _open(BuildContext context, WidgetRef ref) {
    _markRead(ref);
    final apptId = notification.appointmentId;
    if (apptId != null && apptId.isNotEmpty) {
      context.push('/appointments/$apptId');
      return;
    }
    if (notification.type == NotificationType.appointment) {
      context.push('/appointments');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canOpen = notification.appointmentId != null && notification.appointmentId!.isNotEmpty;
    final accent = _accent(context);

    return InkWell(
      onTap: canOpen ? () => _open(context, ref) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withValues(alpha: 0.12),
              child: Icon(_icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                      color: context.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.35,
                      color: context.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(notification.timestamp),
                    style: GoogleFonts.poppins(fontSize: 11, color: context.hintText),
                  ),
                  if (canOpen) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _open(context, ref),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: accent,
                      ),
                      child: Text(
                        'Open the notification',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!read)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
