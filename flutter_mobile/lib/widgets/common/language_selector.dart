import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medichain_mobile/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/l10n_extension.dart';
import '../../providers/locale_provider.dart';

/// Compact dropdown for login / emergency headers.
class LanguageSelectorCompact extends ConsumerWidget {
  const LanguageSelectorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: locale.languageCode,
        isDense: true,
        icon: Icon(Icons.language, size: 20, color: cs.primary),
        items: [
          DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish, style: _itemStyle(context))),
          DropdownMenuItem(value: 'te', child: Text(l10n.languageTelugu, style: _itemStyle(context))),
          DropdownMenuItem(value: 'hi', child: Text(l10n.languageHindi, style: _itemStyle(context))),
        ],
        onChanged: (code) {
          if (code != null) {
            ref.read(localeProvider.notifier).setLocale(AppLocales.fromCode(code));
          }
        },
      ),
    );
  }

  TextStyle _itemStyle(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface);
}

/// Full language card for Settings (matches Appearance block style).
class LanguageSelectorCard extends ConsumerWidget {
  const LanguageSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
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
              Icon(Icons.language, color: cs.primary),
              const SizedBox(width: 12),
              Text(
                l10n.languageTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.languageEnglish, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ButtonSegment(value: 'te', label: Text(l10n.languageTelugu, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ButtonSegment(value: 'hi', label: Text(l10n.languageHindi, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (value) {
              ref.read(localeProvider.notifier).setLocale(AppLocales.fromCode(value.first));
            },
          ),
          const SizedBox(height: 10),
          Text(
            l10n.languageSelectHint,
            style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
