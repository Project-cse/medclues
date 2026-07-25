class SpecialityModel {
  final String id;
  final String name;
  final String? iconUrl;
  final int doctorCount;

  const SpecialityModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.doctorCount = 0,
  });

  factory SpecialityModel.fromJson(Map<String, dynamic> json) {
    return SpecialityModel(
      id: '${json['id'] ?? json['_id'] ?? json['name'] ?? ''}',
      name: '${json['name'] ?? json['specialty_name'] ?? ''}',
      iconUrl: json['icon']?.toString() ?? json['image']?.toString(),
      doctorCount: json['doctorCount'] is int
          ? json['doctorCount'] as int
          : int.tryParse('${json['doctor_count'] ?? json['doctorCount'] ?? 0}') ?? 0,
    );
  }
}
