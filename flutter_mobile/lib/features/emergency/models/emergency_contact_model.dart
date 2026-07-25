class EmergencyContactModel {
  const EmergencyContactModel({
    required this.name,
    required this.phone,
    this.relation,
  });

  final String name;
  final String phone;
  final String? relation;

  bool get isValid => name.trim().isNotEmpty && phone.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (relation != null) 'relation': relation,
      };

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString(),
    );
  }

  EmergencyContactModel copyWith({String? name, String? phone, String? relation}) {
    return EmergencyContactModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
    );
  }
}
