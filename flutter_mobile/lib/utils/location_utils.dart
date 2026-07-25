import 'package:geolocator/geolocator.dart';

/// Haversine distance in km (matches web locationUtils.js).
double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
}

String formatDistanceKm(double distanceKm) {
  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()}m';
  }
  return '${distanceKm.toStringAsFixed(1)}km';
}

/// Returns user coordinates; throws with a readable message on failure.
Future<({double lat, double lon})> getUserLocation() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled. Please enable GPS.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw Exception('Location permission denied. Enable it in app settings.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permission permanently denied. Enable it in app settings.');
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 15),
    ),
  );

  return (lat: position.latitude, lon: position.longitude);
}
