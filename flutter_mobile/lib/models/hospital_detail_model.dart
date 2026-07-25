import 'doctor_model.dart';
import 'hospital_model.dart';

class HospitalDetailModel {
  const HospitalDetailModel({
    required this.hospital,
    required this.doctors,
  });

  final HospitalModel hospital;
  final List<DoctorModel> doctors;
}
