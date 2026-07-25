import 'package:image_picker/image_picker.dart';

import '../models/patient_model.dart';
import '../services/patient_service.dart';

class PatientRepository {
  PatientRepository(this._service);

  final PatientService _service;

  Future<PatientModel> getProfile() => _service.getProfile();

  Future<PatientModel> updateProfile(PatientModel patient) => _service.updateProfile(patient);

  Future<PatientModel> updateAddress({required String line1, required String line2}) =>
      _service.updateAddress(line1: line1, line2: line2);

  Future<String?> uploadPhoto(XFile file) => _service.uploadPhoto(file);
}
