import '../data/symptom_specialty_map.dart';
import '../models/doctor_model.dart';
import '../models/hospital_model.dart';
import '../utils/speciality_match.dart';

class SymptomSearchOutcome {
  const SymptomSearchOutcome({
    required this.match,
    required this.doctors,
    required this.hospitals,
  });

  final SymptomMatchResult match;
  final List<DoctorModel> doctors;
  final List<HospitalModel> hospitals;
}

/// Filter doctors & hospitals for a symptom / disease query.
SymptomSearchOutcome searchBySymptom({
  required String query,
  required List<DoctorModel> allDoctors,
  required List<HospitalModel> allHospitals,
}) {
  final match = resolveSymptomQuery(query);
  if (!match.hasMatch) {
    return SymptomSearchOutcome(match: match, doctors: const [], hospitals: const []);
  }

  final specialties = match.specialties;

  final doctors = allDoctors.where((d) {
    return specialties.any((s) => matchesSpeciality(d.specialization, s));
  }).toList()
    ..sort((a, b) {
      final ra = a.rating ?? 0;
      final rb = b.rating ?? 0;
      return rb.compareTo(ra);
    });

  // Hospitals: specialty field match OR has a matching doctor at that hospital.
  final doctorHospitalNames = doctors
      .map((d) => (d.hospitalName ?? '').trim().toLowerCase())
      .where((n) => n.isNotEmpty)
      .toSet();

  final hospitals = allHospitals.where((h) {
    final spec = (h.specialization ?? '').toLowerCase();
    final name = h.name.toLowerCase();
    final type = (h.type ?? '').toLowerCase();
    final blob = '$spec $name $type';

    final byField = specialties.any((s) => matchesSpeciality(blob, s) || blob.contains(s));
    if (byField) return true;

    final hName = name.trim();
    if (hName.isEmpty) return false;
    return doctorHospitalNames.any(
      (dn) => dn == hName || dn.contains(hName) || hName.contains(dn),
    );
  }).toList()
    ..sort((a, b) {
      final ra = a.rating ?? 0;
      final rb = b.rating ?? 0;
      return rb.compareTo(ra);
    });

  return SymptomSearchOutcome(match: match, doctors: doctors, hospitals: hospitals);
}
