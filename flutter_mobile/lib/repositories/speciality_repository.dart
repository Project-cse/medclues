import '../models/speciality_model.dart';
import '../services/speciality_service.dart';

class SpecialityRepository {
  SpecialityRepository(this._service);

  final SpecialityService _service;

  Future<List<SpecialityModel>> getAll() => _service.fetchAll();
}
