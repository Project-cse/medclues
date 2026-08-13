import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../routes/route_names.dart';
import '../widgets/home/home_promo_carousel.dart';

Color _parseHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  if (v == null) return fallback;
  return Color(v);
}

IconData _iconFor(String? key) {
  switch ((key ?? '').toLowerCase()) {
    case 'pharmacy':
      return Icons.local_pharmacy_outlined;
    case 'doctors':
    case 'doctor':
      return Icons.medical_services_outlined;
    case 'health':
    case 'healthprotection':
      return Icons.health_and_safety_outlined;
    case 'labs':
    case 'lab':
      return Icons.science_outlined;
    case 'blood':
    case 'bloodbanks':
      return Icons.bloodtype_outlined;
    case 'emergency':
      return Icons.emergency_outlined;
    default:
      return Icons.local_hospital_outlined;
  }
}

String _routeFor(String? key) {
  switch (key) {
    case 'pharmacy':
      return RouteNames.pharmacy;
    case 'doctors':
      return RouteNames.doctors;
    case 'healthProtection':
    case 'health_protection':
      return RouteNames.healthProtection;
    case 'labs':
      return RouteNames.labs;
    case 'bloodBanks':
    case 'blood_banks':
      return RouteNames.bloodBanks;
    case 'emergency':
      return RouteNames.emergency;
    case 'hospitals':
    default:
      return RouteNames.hospitals;
  }
}

PromoSlide slideFromApi(Map<String, dynamic> m) {
  return PromoSlide(
    title: '${m['title'] ?? ''}'.trim().isEmpty
        ? 'MedClues'
        : '${m['title']}'.trim(),
    quote: '${m['subtitle'] ?? ''}'.trim(),
    cta: '${m['ctaLabel'] ?? m['cta_label'] ?? 'Explore →'}'.trim(),
    route: _routeFor('${m['routeKey'] ?? m['route_key'] ?? 'hospitals'}'),
    gradient: [
      _parseHex('${m['gradientStart'] ?? m['gradient_start']}', const Color(0xFF002855)),
      _parseHex('${m['gradientMid'] ?? m['gradient_mid']}', const Color(0xFF1565C0)),
      _parseHex('${m['gradientEnd'] ?? m['gradient_end']}', const Color(0xFF7DD3FC)),
    ],
    icon: _iconFor('${m['iconKey'] ?? m['icon_key'] ?? 'hospital'}'),
    imageUrl: (m['imageUrl'] ?? m['image_url'])?.toString(),
  );
}

final homeBannersProvider = FutureProvider.autoDispose<List<PromoSlide>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final res = await api.get<Map<String, dynamic>>(ApiConfig.homeBanners);
    final data = res.data ?? {};
    if (data['success'] != true) return fallbackPromoSlides;
    final raw = data['banners'];
    if (raw is! List || raw.isEmpty) return fallbackPromoSlides;
    final slides = <PromoSlide>[];
    for (final item in raw) {
      if (item is Map) {
        slides.add(slideFromApi(Map<String, dynamic>.from(item)));
      }
    }
    return slides.isEmpty ? fallbackPromoSlides : slides;
  } catch (_) {
    return fallbackPromoSlides;
  }
});
