import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../emergency_constants.dart';
import '../models/emergency_contact_model.dart';
import '../models/emergency_settings_model.dart';
import 'emergency_location_service.dart';

class EmergencyNotificationService {
  String buildAlertMessage({
    required EmergencySettingsModel settings,
    EmergencyLocationData? location,
    String? extraNote,
  }) {
    final time = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final loc = location?.mapsLink ?? 'Location unavailable';
    final buffer = StringBuffer()
      ..writeln('🚨 *MEDCLUES Emergency Alert*')
      ..writeln('The patient may need urgent medical assistance.')
      ..writeln('')
      ..writeln('📍 *Live Location:*')
      ..writeln(loc)
      ..writeln('')
      ..writeln('🕐 Time: $time');
    if (settings.bloodGroup?.isNotEmpty == true) {
      buffer.writeln('🩸 Blood Group: ${settings.bloodGroup}');
    }
    if (settings.allergies?.isNotEmpty == true) {
      buffer.writeln('⚠️ Allergies: ${settings.allergies}');
    }
    if (settings.existingDiseases?.isNotEmpty == true) {
      buffer.writeln('🏥 Conditions: ${settings.existingDiseases}');
    }
    if (settings.currentMedications?.isNotEmpty == true) {
      buffer.writeln('💊 Medications: ${settings.currentMedications}');
    }
    if (extraNote?.isNotEmpty == true) buffer.writeln(extraNote);
    buffer.writeln('');
    buffer.writeln('Please open the location link and respond immediately.');
    return buffer.toString().trim();
  }

  /// Strip non-digits; prepend India 91 for 10-digit numbers.
  String normalizeWhatsAppPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) digits = '91$digits';
    return digits;
  }

  Uri whatsAppMessageUri(String phone, String message) {
    final normalized = normalizeWhatsAppPhone(phone);
    return Uri.parse('https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
  }

  Future<bool> openWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    final uri = whatsAppMessageUri(phone, message);
    return _launchExternal(uri);
  }

  Future<bool> _launchExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Send alert + live location to saved relatives via WhatsApp (first contact).
  Future<void> notifyContacts({
    required List<EmergencyContactModel> contacts,
    required String message,
  }) async {
    if (contacts.isEmpty) {
      await manualShare(message);
      return;
    }
    await openWhatsAppMessage(phone: contacts.first.phone, message: message);
  }

  /// Notify each relative one-by-one via WhatsApp message.
  Future<int> notifyAllContactsWhatsApp({
    required List<EmergencyContactModel> contacts,
    required String message,
  }) async {
    var sent = 0;
    for (final c in contacts) {
      final ok = await openWhatsAppMessage(phone: c.phone, message: message);
      if (ok) sent++;
    }
    return sent;
  }

  Future<void> manualShare(String message) async {
    await Share.share(message, subject: 'MEDCLUES Emergency Alert');
  }

  Future<void> shareViaWhatsAppOrSheet({
    required List<EmergencyContactModel> contacts,
    required String message,
  }) async {
    if (contacts.isNotEmpty) {
      await notifyContacts(contacts: contacts, message: message);
    } else {
      await manualShare(message);
    }
  }
}

/// Blocks real tel: calls to ambulance/police/fire during testing.
Future<bool> launchEmergencyServiceCall({
  required String number,
  required String label,
}) async {
  if (EmergencyConstants.testingMode) return false;
  final uri = Uri.parse('tel:$number');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    return true;
  }
  return false;
}
