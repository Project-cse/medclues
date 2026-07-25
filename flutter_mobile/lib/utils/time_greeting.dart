import '../l10n/app_localizations.dart';

/// Morning / afternoon / evening greeting for the dashboard.
String timeBasedGreeting(AppLocalizations l10n) {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return l10n.dashboardGoodMorning;
  if (hour >= 12 && hour < 17) return l10n.dashboardGoodAfternoon;
  return l10n.dashboardGoodEvening;
}
