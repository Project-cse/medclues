import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class DoctorRepository {
  DoctorRepository(this._service);

  final DoctorService _service;

  Future<List<DoctorModel>> getDoctors({int? hospitalId, bool forceRefresh = false}) =>
      _service.fetchAll(hospitalId: hospitalId, forceRefresh: forceRefresh);

  void invalidateCache() => _service.invalidateCache();

  Future<DoctorModel> getDoctor(String id) => _service.fetchById(id);

  Future<List<DoctorModel>> search(String query, {String? speciality}) =>
      _service.fetchPage(q: query, limit: 50, forceRefresh: true);

  Future<List<DoctorModel>> getTop() => _service.fetchTop();
}
