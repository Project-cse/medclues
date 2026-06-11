import 'package:url_launcher/url_launcher.dart';

/// One-tap maps navigation and clinic phone calls.
class ContactNavigationUtils {
  ContactNavigationUtils._();

  static String mapsSearchUrl(String query) {
    final q = Uri.encodeComponent(query.trim());
    return 'https://www.google.com/maps/search/?api=1&query=$q';
  }

  static String mapsNavigateUrl(String query) {
    final q = Uri.encodeComponent(query.trim());
    return 'https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=driving';
  }

  static Future<bool> openHospitalNavigation({
    String? address,
    String? hospitalName,
    String? location,
  }) async {
    final parts = <String>[
      if (hospitalName != null && hospitalName.trim().isNotEmpty) hospitalName.trim(),
      if (location != null && location.trim().isNotEmpty) location.trim(),
      if (address != null && address.trim().isNotEmpty) address.trim(),
    ];
    if (parts.isEmpty) return false;
    final uri = Uri.parse(mapsNavigateUrl(parts.join(', ')));
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> callClinic(String? phone) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.replaceAll('+', '').length < 10) return false;
    final tel = digits.startsWith('+') ? digits : '+91${digits.replaceAll(RegExp(r'\D'), '')}';
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
