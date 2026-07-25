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

  /// Opens the hospital on the map. Prefers a saved maps link, then a
  /// name + address search (so Maps shows the hospital NAME, not raw
  /// coordinates), and only falls back to lat/lon when no name is available.
  static Future<bool> openHospitalLocation({
    double? latitude,
    double? longitude,
    String? mapsLink,
    String? hospitalName,
    String? address,
  }) async {
    final direct = (mapsLink ?? '').trim();
    if (direct.isNotEmpty) {
      final normalized = direct.startsWith('http') ? direct : 'https://$direct';
      final uri = Uri.tryParse(normalized);
      if (uri != null && await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    final parts = <String>[
      if (hospitalName != null && hospitalName.trim().isNotEmpty) hospitalName.trim(),
      if (address != null && address.trim().isNotEmpty) address.trim(),
    ];
    if (parts.isNotEmpty) {
      // Anchor the named search to the precise coordinates when we have them so
      // it lands on the right pin while still displaying the hospital name.
      final hasCoords = latitude != null && longitude != null;
      final query = parts.join(', ');
      final url = hasCoords
          ? '${mapsSearchUrl(query)}&center=$latitude,$longitude'
          : mapsSearchUrl(query);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (latitude != null && longitude != null) {
      final uri = Uri.parse(mapsSearchUrl('$latitude,$longitude'));
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    return false;
  }

  static Future<bool> openHospitalNavigation({
    String? address,
    String? hospitalName,
    String? location,
    String? mapsLink,
  }) async {
    final direct = (mapsLink ?? '').trim();
    if (direct.isNotEmpty) {
      final normalized = direct.startsWith('http') ? direct : 'https://$direct';
      final uri = Uri.tryParse(normalized);
      if (uri != null && await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

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
