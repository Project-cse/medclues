import '../models/doctor_model.dart';
import '../models/hospital_model.dart';

/// Stats derived from live hospital + doctor API data (no hardcoded placeholders).
class HospitalComputedStats {
  const HospitalComputedStats({
    required this.doctorCount,
    required this.departmentCount,
    required this.averageRating,
    required this.emergencyLabel,
  });

  final int doctorCount;
  final int departmentCount;
  final String? averageRating;
  final String emergencyLabel;

  String get doctorCountLabel => '$doctorCount';

  String get departmentCountLabel => '$departmentCount';

  String get ratingLabel => averageRating ?? '—';

  static HospitalComputedStats from(HospitalModel hospital, List<DoctorModel> doctors) {
    final departments = <String>{};
    for (final d in doctors) {
      final key = d.specialization.trim().toLowerCase();
      if (key.isNotEmpty) departments.add(key);
    }

    final rated = doctors.where((d) => d.hasRating).map((d) => d.rating!).toList();
    String? avg;
    if (rated.isNotEmpty) {
      avg = (rated.reduce((a, b) => a + b) / rated.length).toStringAsFixed(1);
    } else if (hospital.rating != null && hospital.rating! > 0) {
      avg = hospital.rating!.toStringAsFixed(1);
    }

    final emergency = hospital.emergencyLabel?.trim();
    final emergencyLabel = (emergency != null && emergency.isNotEmpty)
        ? emergency
        : (hospital.emergencyAvailable == true ? '24/7' : '—');

    return HospitalComputedStats(
      doctorCount: doctors.length,
      departmentCount: departments.length,
      averageRating: avg,
      emergencyLabel: emergencyLabel,
    );
  }
}
