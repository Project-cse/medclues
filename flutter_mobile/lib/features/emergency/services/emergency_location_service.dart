import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyLocationData {
  const EmergencyLocationData({
    required this.latitude,
    required this.longitude,
    required this.mapsLink,
  });

  final double latitude;
  final double longitude;
  final String mapsLink;
}

class EmergencyLocationService {
  Future<bool> ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<EmergencyLocationData?> getCurrentLocation({bool requestIfNeeded = true}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    if (requestIfNeeded) {
      final ok = await ensurePermission();
      if (!ok) return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      return EmergencyLocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        mapsLink: mapsLink(pos.latitude, pos.longitude),
      );
    } catch (_) {
      return null;
    }
  }

  static String mapsLink(double lat, double lng) => 'https://maps.google.com/?q=$lat,$lng';

  Future<void> openMapsLink(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openNearbyHospitals({EmergencyLocationData? location}) async {
    final loc = location ?? await getCurrentLocation();
    final uri = loc != null
        ? Uri.parse(
            'https://www.google.com/maps/search/nearby+hospitals/@${loc.latitude},${loc.longitude},15z',
          )
        : Uri.parse('https://www.google.com/maps/search/nearby+hospitals');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
