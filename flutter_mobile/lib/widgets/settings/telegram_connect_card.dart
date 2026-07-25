import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/api_config.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/service_providers.dart';
import '../../providers/telegram_link_provider.dart';
import '../../services/telegram_link_service.dart';
import '../../utils/telegram_launcher.dart';
import '../common/app_snackbar.dart';

/// [forLinkedUsers] — Settings (connected: manage / disconnect).
/// [forUnlinkedUsers] — Profile (prompt to connect).
class TelegramConnectCard extends ConsumerStatefulWidget {
  const TelegramConnectCard({
    super.key,
    this.forLinkedUsers = false,
    this.forUnlinkedUsers = false,
  });

  final bool forLinkedUsers;
  final bool forUnlinkedUsers;

  @override
  ConsumerState<TelegramConnectCard> createState() => _TelegramConnectCardState();
}

class _TelegramConnectCardState extends ConsumerState<TelegramConnectCard> {
  bool _loading = false;

  Future<void> _showInstallTelegramDialog() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsTelegramInstallTitle),
        content: Text(l10n.settingsTelegramInstallBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openTelegramStore();
            },
            child: Text(l10n.settingsTelegramGetApp),
          ),
        ],
      ),
    );
  }

  Future<bool> _openDeepLink(String link) async {
    final opened = await openTelegramLink(link);
    if (!opened && mounted) {
      await _showInstallTelegramDialog();
    }
    return opened;
  }

  Future<void> _connect() async {
    setState(() => _loading = true);
    try {
      final info = await ref.read(telegramLinkServiceProvider).createLinkCode();
      if (!mounted) return;

      final link = info.deepLink;
      if (link == null || link.isEmpty) {
        AppSnackbar.show(context, context.l10n.settingsTelegramOpenFailed);
        return;
      }
      await _openDeepLink(link);
      ref.invalidate(telegramLinkStatusProvider);
    } on TelegramLinkException catch (e) {
      if (!mounted) return;
      if (e.isNotFound) {
        final bot = ApiConfig.telegramBotUsername;
        final fallback = 'https://t.me/$bot';
        final opened = await _openDeepLink(fallback);
        if (mounted) {
          AppSnackbar.show(
            context,
            opened
                ? context.l10n.settingsTelegramServerPending
                : context.l10n.settingsTelegramOpenFailed,
          );
        }
      } else {
        AppSnackbar.show(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsTelegramDisconnectTitle),
        content: Text(l10n.settingsTelegramDisconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsTelegramDisconnect),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(telegramLinkServiceProvider).disconnect();
      ref.invalidate(telegramLinkStatusProvider);
      if (mounted) {
        AppSnackbar.show(context, l10n.settingsTelegramDisconnected, success: true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(telegramLinkStatusProvider);
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) => _buildCard(context, info),
    );
  }

  Widget _buildCard(BuildContext context, TelegramLinkInfo info) {
    final linked = info.linked;
    if (widget.forLinkedUsers && !linked) return const SizedBox.shrink();
    if (widget.forUnlinkedUsers && linked) return const SizedBox.shrink();

    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.telegram, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linked ? l10n.settingsTelegramManageTitle : l10n.settingsTelegramTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.settingsTelegramSubtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (linked) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.settingsTelegramConnected}'
                    '${info.telegramUsername != null ? ' (@${info.telegramUsername})' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : (linked ? _disconnect : _connect),
              style: linked
                  ? FilledButton.styleFrom(backgroundColor: cs.error)
                  : null,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(linked ? Icons.link_off_rounded : Icons.link_rounded, size: 20),
              label: Text(
                linked ? l10n.settingsTelegramDisconnect : l10n.settingsTelegramConnect,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
