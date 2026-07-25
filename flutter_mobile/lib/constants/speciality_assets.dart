import '../utils/speciality_match.dart';

/// Web frontend icon paths (assets.js specialityData mapping).
class SpecialityAssets {
  SpecialityAssets._();

  static const _web = 'assets/images/specialities/web';

  static String? assetPathFor(String specialityName) {
    final key = canonicalSpecialityKey(specialityName) ?? specialityName.toLowerCase();
    switch (key) {
      case 'cardiology':
        return '$_web/cardiology.png';
      case 'orthopedics':
        return '$_web/orthopedics.png';
      case 'psychiatry':
        return '$_web/psychiatry.png';
      case 'ophthalmology':
        return '$_web/ophthalmology.png';
      case 'ent':
        return '$_web/ent.png';
      case 'dentistry':
        return '$_web/dentistry.png';
      case 'general medicine':
      case 'general physician':
        return '$_web/general-medicine.svg';
      case 'gynecology':
        return '$_web/gynecology.svg';
      case 'dermatology':
        return '$_web/dermatology.svg';
      case 'pediatrics':
        return '$_web/pediatrics.svg';
      case 'neurology':
        return '$_web/neurology.svg';
      case 'gastroenterology':
        return '$_web/gastroenterology.svg';
      default:
        return null;
    }
  }

  static bool isSvg(String path) => path.endsWith('.svg');
}
