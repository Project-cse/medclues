import 'dart:convert';

/// Blood type stock status for UI (matches web BloodBankCard.jsx).
enum BloodStockStatus { available, limited, unavailable }

extension BloodStockStatusUi on BloodStockStatus {
  String get displayLabel => switch (this) {
        BloodStockStatus.available => 'Available',
        BloodStockStatus.limited => 'Limited',
        BloodStockStatus.unavailable => 'Unavailable',
      };
}

class BloodBankModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? imageUrl;
  final String? phone;
  final bool partner;
  final Map<String, BloodStockStatus> availability;

  const BloodBankModel({
    required this.id,
    required this.name,
    required this.address,
    this.city = '',
    this.imageUrl,
    this.phone,
    this.partner = false,
    this.availability = const {},
  });

  static const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  BloodStockStatus statusFor(String type) =>
      availability[type] ?? BloodStockStatus.unavailable;

  factory BloodBankModel.fromJson(Map<String, dynamic> json) {
    final availability = <String, BloodStockStatus>{};
    dynamic bloodRaw = json['available_blood'] ?? json['availableBlood'] ?? json['availability'];

    if (bloodRaw is String && bloodRaw.trim().isNotEmpty) {
      try {
        bloodRaw = jsonDecode(bloodRaw);
      } catch (_) {
        bloodRaw = null;
      }
    }

    if (bloodRaw is Map) {
      for (final entry in bloodRaw.entries) {
        final type = '${entry.key}'.trim();
        if (type.isEmpty) continue;
        availability[type] = _statusFromValue(entry.value);
      }
    }

    final city = '${json['city'] ?? ''}'.trim();
    final location = '${json['location'] ?? json['address'] ?? ''}'.trim();
    final partnerType = '${json['partner_type'] ?? json['partnerType'] ?? ''}'.toLowerCase();

    return BloodBankModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      name: '${json['name'] ?? 'Blood Bank'}',
      address: location.isNotEmpty ? location : city,
      city: city.isNotEmpty ? city : location,
      imageUrl: json['image']?.toString(),
      phone: json['phone']?.toString() ?? json['contact']?.toString(),
      partner: partnerType == 'partner' || json['partner'] == true,
      availability: availability,
    );
  }

  static BloodStockStatus _statusFromValue(dynamic v) {
    if (v is num) {
      if (v <= 0) return BloodStockStatus.unavailable;
      if (v < 3) return BloodStockStatus.limited;
      return BloodStockStatus.available;
    }
    final s = '$v'.trim().toLowerCase();
    if (s.contains('limit')) return BloodStockStatus.limited;
    if (s.contains('avail') || s.contains('in stock') || s == 'yes' || s == 'true') {
      return BloodStockStatus.available;
    }
    return BloodStockStatus.unavailable;
  }
}
