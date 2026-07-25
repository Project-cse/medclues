class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final String? backgroundImage;
  final double? rating;
  final String? specialization;
  final String? type;
  final String? contact;
  final String? mapsLink;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final bool isRealHospital;
  final String? hospitalType;
  final bool? emergencyAvailable;
  final String? emergencyLabel;
  final int? doctorCount;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.backgroundImage,
    this.rating,
    this.specialization,
    this.type,
    this.contact,
    this.mapsLink,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.isRealHospital = false,
    this.hospitalType,
    this.emergencyAvailable,
    this.emergencyLabel,
    this.doctorCount,
  });

  bool get canOpenDetails => !isRealHospital && id.isNotEmpty;

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lon;
    final latRaw = json['latitude'] ?? json['lat'];
    final lonRaw = json['longitude'] ?? json['lon'] ?? json['lng'];
    if (latRaw is num) lat = latRaw.toDouble();
    if (lonRaw is num) lon = lonRaw.toDouble();
    final coords = json['coordinates'];
    if (coords is Map) {
      lat ??= (coords['lat'] as num?)?.toDouble();
      lon ??= (coords['lon'] as num?)?.toDouble();
    }

    return HospitalModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      name: '${json['name'] ?? json['hospitalName'] ?? 'Hospital'}',
      address: '${json['address'] ?? json['location'] ?? ''}',
      imageUrl: (json['image'] ?? json['profile_pic_url'] ?? json['backgroundImage'] ?? json['background_image'])?.toString(),
      backgroundImage: (json['backgroundImage'] ?? json['background_image'])?.toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : null,
      specialization: json['specialization']?.toString(),
      type: json['type']?.toString(),
      contact: json['contact']?.toString(),
      mapsLink: (json['mapsLink'] ?? json['maps_link'])?.toString(),
      latitude: lat,
      longitude: lon,
      distanceKm: (json['distance'] is num) ? (json['distance'] as num).toDouble() : null,
      isRealHospital: json['isRealHospital'] == true,
      hospitalType: json['hospitalType']?.toString(),
      emergencyAvailable: json['emergencyAvailable'] == true,
      emergencyLabel: json['emergencyLabel']?.toString(),
      doctorCount: json['doctorCount'] is int
          ? json['doctorCount'] as int
          : int.tryParse('${json['doctor_count'] ?? json['doctorCount'] ?? ''}'),
    );
  }

  String get displayBadge {
    final tag = (hospitalType ?? type ?? '').trim();
    return tag.isEmpty ? 'HOSPITAL' : tag.toUpperCase();
  }

  HospitalModel copyWith({
    double? distanceKm,
    bool? isRealHospital,
  }) {
    return HospitalModel(
      id: id,
      name: name,
      address: address,
      imageUrl: imageUrl,
      backgroundImage: backgroundImage,
      rating: rating,
      specialization: specialization,
      type: type,
      contact: contact,
      mapsLink: mapsLink,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      isRealHospital: isRealHospital ?? this.isRealHospital,
      hospitalType: hospitalType,
      emergencyAvailable: emergencyAvailable,
      emergencyLabel: emergencyLabel,
      doctorCount: doctorCount,
    );
  }
}
