import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/api_config.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/service_providers.dart';
import '../../services/telegram_link_service.dart';
import '../../utils/telegram_launcher.dart';
import '../common/app_snackbar.dart';

class TelegramConnectCard extends ConsumerStatefulWidget {
  const TelegramConnectCard({super.key});

  @override
  ConsumerState<TelegramConnectCard> createState() => _TelegramConnectCardState();
}

class _TelegramConnectCardState extends ConsumerState<TelegramConnectCard> {
  bool _loading = false;
  TelegramLinkInfo? _info;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    try {
      final info = await ref.read(telegramLinkServiceProvider).fetchStatus();
      if (mounted) setState(() => _info = info);
    } catch (_) {}
  }

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
      setState(() => _info = info);

      final link = info.deepLink;
      if (link == null || link.isEmpty) {
        AppSnackbar.show(context, context.l10n.settingsTelegramOpenFailed);
        return;
      }
      await _openDeepLink(link);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final linked = _info?.linked == true;

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
                      l10n.settingsTelegramTitle,
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
                    '${_info?.telegramUsername != null ? ' (@${_info!.telegramUsername})' : ''}',
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
              onPressed: _loading ? null : _connect,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.link_rounded, size: 20),
              label: Text(l10n.settingsTelegramConnect),
            ),
          ),
        ],
      ),
    );
  }
}
