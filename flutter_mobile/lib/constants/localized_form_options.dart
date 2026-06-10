import 'package:medichain_mobile/l10n/app_localizations.dart';

import 'form_options.dart';

/// Localized display labels for form dropdowns; storage values stay English codes.
class LocalizedFormOptions {
  LocalizedFormOptions._();

  static List<String> genders(AppLocalizations l10n) => [
        l10n.genderMale,
        l10n.genderFemale,
        l10n.genderOther,
        l10n.genderPreferNotToSay,
      ];

  static List<String> relationships(AppLocalizations l10n) => [
        l10n.relationshipFather,
        l10n.relationshipMother,
        l10n.relationshipBrother,
        l10n.relationshipSister,
        l10n.relationshipSpouse,
        l10n.relationshipSon,
        l10n.relationshipDaughter,
        l10n.relationshipGuardian,
        l10n.relationshipFriend,
        l10n.relationshipOther,
      ];

  /// Map localized gender label back to English storage value for API.
  static String genderToStorage(String localized, AppLocalizations l10n) {
    if (localized == l10n.genderMale) return FormOptions.genders[0];
    if (localized == l10n.genderFemale) return FormOptions.genders[1];
    if (localized == l10n.genderOther) return FormOptions.genders[2];
    if (localized == l10n.genderPreferNotToSay) return FormOptions.genders[3];
    return localized;
  }

  static String genderFromStorage(String? stored, AppLocalizations l10n) {
    final labels = genders(l10n);
    final codes = FormOptions.genders;
    final idx = codes.indexWhere((c) => c.toLowerCase() == (stored ?? '').toLowerCase());
    if (idx >= 0 && idx < labels.length) return labels[idx];
    if (stored == 'Male' || stored == 'male') return l10n.genderMale;
    if (stored == 'Female' || stored == 'female') return l10n.genderFemale;
    if (stored == 'Other' || stored == 'other') return l10n.genderOther;
    return l10n.genderMale;
  }

  static String relationshipToStorage(String localized, AppLocalizations l10n) {
    final labels = relationships(l10n);
    final codes = FormOptions.relationships;
    final idx = labels.indexOf(localized);
    if (idx >= 0 && idx < codes.length) return codes[idx];
    return localized;
  }

  static String relationshipFromStorage(String? stored, AppLocalizations l10n) {
    final labels = relationships(l10n);
    final codes = FormOptions.relationships;
    final idx = codes.indexOf(stored ?? '');
    if (idx >= 0 && idx < labels.length) return labels[idx];
    return labels.first;
  }
}
