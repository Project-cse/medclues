import 'package:file_picker/file_picker.dart';

import '../models/appointment_model.dart';
import '../models/patient_booking_info.dart';
import '../models/slot_model.dart';
import '../services/appointment_service.dart';

class AppointmentRepository {
  AppointmentRepository(this._service);

  final AppointmentService _service;

  Future<List<AppointmentModel>> upcoming() => _service.fetchAppointments(statusFilter: 'upcoming');

  Future<List<AppointmentModel>> past() => _service.fetchAppointments(statusFilter: 'past');

  Future<List<AppointmentModel>> cancelled() => _service.fetchAppointments(statusFilter: 'cancelled');

  Future<List<AppointmentModel>> fetchAll() => _service.fetchAppointments();

  Future<AppointmentModel> getById(String id) => _service.fetchById(id);

  Future<Map<String, DaySlotsModel>> doctorSchedule(String doctorId, {String mode = 'offline'}) =>
      _service.fetchDoctorSchedule(doctorId, mode: mode);

  DaySlotsModel? dayOf(Map<String, DaySlotsModel> schedule, String date) =>
      _service.dayFromSchedule(schedule, date);

  Future<DaySlotsModel> slots(String doctorId, String date, {String mode = 'offline'}) =>
      _service.fetchSlots(doctorId, date, mode: mode);

  Future<Map<String, dynamic>> book({
    required String doctorId,
    required String slotDate,
    required String slotTime,
    List<String>? symptoms,
    String? notes,
    String? hospitalName,
    String? location,
    PatientBookingInfo? patient,
    String paymentMethod = 'payOnVisit',
    String? visitType,
    String? mode,
    int? slotId,
    String? slotType,
    PlatformFile? prescription,
  }) =>
      _service.book(
        doctorId: doctorId,
        slotDate: slotDate,
        slotTime: slotTime,
        symptoms: symptoms,
        notes: notes,
        hospitalName: hospitalName,
        location: location,
        patient: patient,
        paymentMethod: paymentMethod,
        visitType: visitType,
        mode: mode,
        slotId: slotId,
        slotType: slotType,
        prescription: prescription,
      );

  Future<void> cancel(String id) => _service.cancel(id);
}
