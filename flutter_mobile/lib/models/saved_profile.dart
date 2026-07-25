import 'patient_booking_info.dart';

class SavedProfile {
  const SavedProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.relationship,
    required this.phone,
  });

  final String id;
  final String name;
  final String age;
  final String gender;
  final String relationship;
  final String phone;

  factory SavedProfile.fromJson(Map<String, dynamic> json) => SavedProfile(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        age: '${json['age'] ?? ''}',
        gender: '${json['gender'] ?? ''}',
        relationship: '${json['relationship'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'relationship': relationship,
        'phone': phone,
      };

  PatientBookingInfo toPatientBookingInfo() => PatientBookingInfo(
        name: name,
        age: age,
        gender: gender,
        relationship: relationship,
        phone: phone,
        isSelf: false,
      );
}
