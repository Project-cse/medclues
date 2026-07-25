import 'package:flutter/widgets.dart';
import 'package:medichain_mobile/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
