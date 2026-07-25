/// Patient details for appointment booking (web AppointmentBookingModal parity).
class PatientBookingInfo {
  const PatientBookingInfo({
    required this.name,
    this.age,
    this.gender,
    this.phone,
    this.relationship,
    this.symptoms,
    this.isSelf = true,
  });

  final String name;
  final String? age;
  final String? gender;
  final String? phone;
  final String? relationship;
  final String? symptoms;
  final bool isSelf;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (age != null && age!.isNotEmpty) 'age': age,
        if (gender != null && gender!.isNotEmpty) 'gender': gender,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (relationship != null && relationship!.isNotEmpty) 'relationship': relationship,
        if (symptoms != null && symptoms!.isNotEmpty) 'symptoms': symptoms,
        'isSelf': isSelf,
      };

  factory PatientBookingInfo.self({
    required String name,
    String? phone,
    String? gender,
    String? age,
  }) {
    return PatientBookingInfo(
      name: name,
      phone: phone,
      gender: gender,
      age: age,
      relationship: 'Self',
      isSelf: true,
    );
  }
}
