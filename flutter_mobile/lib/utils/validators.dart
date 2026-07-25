import 'package:medichain_mobile/l10n/app_localizations.dart';

class Validators {
  Validators._();

  static final _patientNameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');
  static final _doctorNameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');
  static final _emergencyNameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');
  static final _emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
  static final _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');
  static final _otpRegex = RegExp(r'^\d{6}$');
  static final _addressRegex = RegExp(r'^[A-Za-z0-9 ,\-/]+$');
  static final _htmlTagRegex = RegExp(r'<[^>]*>');
  static final _passwordUpper = RegExp(r'[A-Z]');
  static final _passwordLower = RegExp(r'[a-z]');
  static final _passwordDigit = RegExp(r'\d');
  static final _passwordSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]');

  static String trimText(String? value) => (value ?? '').trim();

  static String sanitizeText(String? value, {int? maxLength}) {
    var t = trimText(value);
    t = t.replaceAll(_htmlTagRegex, '');
    if (maxLength != null && t.length > maxLength) {
      t = t.substring(0, maxLength);
    }
    return t;
  }

  static String? patientName(String? value, AppLocalizations l10n) {
    final t = trimText(value);
    if (t.isEmpty) return l10n.validationPatientNameRequired;
    if (t.length < 2) return l10n.validationNameMin2;
    if (t.length > 50) return l10n.validationNameMax50;
    if (!_patientNameRegex.hasMatch(t)) return l10n.validationNameLettersOnly;
    return null;
  }

  static String? doctorName(String? value, AppLocalizations l10n) {
    final t = trimText(value);
    if (t.isEmpty) return l10n.validationDoctorNameRequired;
    if (t.length < 3) return l10n.validationNameMin3;
    if (t.length > 60) return l10n.validationNameMax60;
    if (!_doctorNameRegex.hasMatch(t)) return l10n.validationNameLettersOnly;
    return null;
  }

  static String? age(String? value, AppLocalizations l10n) {
    final t = trimText(value);
    if (t.isEmpty) return l10n.validationAgeRequired;
    if (!RegExp(r'^\d+$').hasMatch(t)) return l10n.validationAgeInvalid;
    final n = int.tryParse(t);
    if (n == null) return l10n.validationAgeInvalid;
    if (n < 0 || n > 120) return l10n.validationAgeInvalid;
    return null;
  }

  static String? indianPhone(String? value, AppLocalizations l10n, {bool required = true}) {
    final t = trimText(value);
    if (t.isEmpty) return required ? l10n.validationPhoneRequired : null;
    if (!_indianPhoneRegex.hasMatch(t)) return l10n.validationPhoneInvalid;
    return null;
  }

  static String? email(String? value, AppLocalizations l10n, {bool required = true}) {
    final t = trimText(value);
    if (t.isEmpty) return required ? l10n.validationEmailRequired : null;
    if (t.length > 100) return l10n.validationEmailMax;
    if (!_emailRegex.hasMatch(t)) return l10n.validationEmailInvalid;
    return null;
  }

  /// Sign-in only — non-empty check. Do not enforce signup complexity rules.
  static String? loginPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
    return null;
  }

  /// Sign-in only — non-empty email. Format/credentials checked by API.
  static String? loginEmail(String? value, AppLocalizations l10n) {
    if (value == null || trimText(value).isEmpty) return l10n.validationEmailRequired;
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
    if (value.length < 8) return l10n.validationPasswordMin;
    if (value.length > 32) return l10n.validationPasswordMax;
    if (!_passwordUpper.hasMatch(value)) return l10n.validationPasswordUpper;
    if (!_passwordLower.hasMatch(value)) return l10n.validationPasswordLower;
    if (!_passwordDigit.hasMatch(value)) return l10n.validationPasswordNumber;
    if (!_passwordSpecial.hasMatch(value)) return l10n.validationPasswordSpecial;
    return null;
  }

  static String? confirmPassword(String? value, String password, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.validationConfirmPassword;
    if (value != password) return l10n.validationPasswordMismatch;
    return null;
  }

  static String? otp(String? value, AppLocalizations l10n) {
    final t = trimText(value);
    if (t.isEmpty) return l10n.validationOtpRequired;
    if (!_otpRegex.hasMatch(t)) return l10n.validationOtpInvalid;
    return null;
  }

  static String? requiredField(String? value, String label, AppLocalizations l10n) {
    if (value == null || trimText(value).isEmpty) {
      return l10n.validationFieldRequired(label);
    }
    return null;
  }

  static String? phone(String? value, AppLocalizations l10n) => indianPhone(value, l10n);

  static String? address(String? value, AppLocalizations l10n, {bool required = false}) {
    final t = sanitizeText(value, maxLength: 250);
    if (t.isEmpty) return required ? l10n.validationAddressRequired : null;
    if (t.length > 250) return l10n.validationAddressMax;
    if (!_addressRegex.hasMatch(t)) return l10n.validationAddressChars;
    return null;
  }

  static String? appointmentReason(String? value, AppLocalizations l10n, {bool required = false}) {
    final t = sanitizeText(value, maxLength: 500);
    if (t.isEmpty) return required ? l10n.validationReasonRequired : null;
    if (t.length < 5) return l10n.validationReasonMin;
    if (t.length > 500) return l10n.validationReasonMax;
    return null;
  }

  static String? reportTitle(String? value, AppLocalizations l10n) {
    final t = sanitizeText(value, maxLength: 100);
    if (t.isEmpty) return l10n.validationReportTitleRequired;
    if (t.length < 3) return l10n.validationTitleMin3;
    if (t.length > 100) return l10n.validationTitleMax100;
    return null;
  }

  static String? emergencyContactName(String? value, AppLocalizations l10n) {
    final t = trimText(value);
    if (t.isEmpty) return l10n.validationEmergencyNameRequired;
    if (t.length > 50) return l10n.validationNameMax50;
    if (!_emergencyNameRegex.hasMatch(t)) return l10n.validationNameLettersOnly;
    return null;
  }

  static String? emergencyContactPhone(String? value, AppLocalizations l10n) {
    return indianPhone(value, l10n);
  }

  static String? dobMatchesAge(String? dobIso, String? ageText, AppLocalizations l10n) {
    if (dobIso == null || dobIso.isEmpty) return null;
    final dob = DateTime.tryParse(dobIso);
    if (dob == null) return l10n.validationDobInvalid;
    if (dob.isAfter(DateTime.now())) return l10n.validationDobFuture;
    final ageErr = age(ageText, l10n);
    if (ageErr != null) return ageErr;
    final expected = _ageFromDob(dob);
    final entered = int.parse(trimText(ageText));
    if (entered != expected) return l10n.validationAgeDobMismatch;
    return null;
  }

  static int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }
}
