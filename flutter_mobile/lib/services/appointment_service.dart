import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';
import '../models/appointment_model.dart';
import '../models/patient_booking_info.dart';
import '../models/slot_model.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class AppointmentService {
  AppointmentService(this._api);

  final ApiService _api;

  Future<List<AppointmentModel>> fetchAppointments({String? statusFilter}) async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.userAppointments);
    final data = res.data ?? {};
    assertSuccess(data);
    var list = unwrapList(data, ['appointments']).map(AppointmentModel.fromJson).toList();
    if (statusFilter == null) return list;
    final s = statusFilter.toLowerCase();
    if (s == 'cancelled') {
      return list.where((a) => a.cancelled || a.status == 'cancelled').toList();
    }
    if (s == 'past' || s == 'completed') {
      return list.where((a) => a.isCompleted || a.status == 'completed').toList();
    }
    return list
        .where((a) =>
            !a.cancelled &&
            !a.isCompleted &&
            a.status != 'cancelled' &&
            a.status != 'completed')
        .toList();
  }

  Future<AppointmentModel> fetchById(String id) async {
    final all = await fetchAppointments();
    return all.firstWhere((a) => a.id == id, orElse: () => throw Exception('Appointment not found'));
  }

  String? _dayKey(Map<String, dynamic> day) {
    final padded = day['slotDatePadded']?.toString();
    if (padded != null && padded.isNotEmpty) return padded;
    final legacy = day['slotDate']?.toString();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    final iso = day['date']?.toString();
    if (iso != null && iso.isNotEmpty) return iso;
    return null;
  }

  List<SlotModel> _parseSlotsForDay(Map<String, dynamic> dayMeta, String mode) {
    final slots = <SlotModel>[];
    if (mode == 'online') {
      for (final raw in (dayMeta['slots'] as List?) ?? []) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final display = '${m['display'] ?? ''}'.trim();
        if (display.isEmpty) continue;
        slots.add(SlotModel(
          time: display,
          displayTime: display,
          available: m['available'] != false,
          slotId: (m['slot_id'] as num?)?.toInt(),
          slotType: m['slot_type']?.toString() ?? 'video',
        ));
      }
    } else {
      for (final raw in (dayMeta['blocks'] as List?) ?? []) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final display = '${m['display'] ?? m['label'] ?? ''}'.trim();
        if (display.isEmpty) continue;
        final slotId = (m['slot_id'] ?? m['representative_slot_id']) as num?;
        final avail = (m['available_count'] as num?)?.toInt();
        final total = (m['total_count'] as num?)?.toInt();
        slots.add(SlotModel(
          time: display,
          displayTime: display,
          available: m['bookable'] != false && (avail ?? 1) > 0,
          slotId: slotId?.toInt(),
          slotType: m['slot_type']?.toString(),
          availableCount: avail,
          totalCount: total,
        ));
      }
      slots.sort(compareOpdSlotOrder);
    }
    return slots;
  }

  DaySlotsModel _daySlotsFromMeta(Map<String, dynamic> dayMeta, String slotDateKey, String mode) {
    return DaySlotsModel(
      date: slotDateKey,
      displayDate: dayMeta['displayDate']?.toString() ?? slotDateKey,
      slots: _parseSlotsForDay(dayMeta, mode),
    );
  }

  /// Fetches the full 5-day schedule in one API call (cached client-side per doctor + mode).
  Future<Map<String, DaySlotsModel>> fetchDoctorSchedule(
    String doctorId, {
    String mode = 'offline',
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiConfig.doctorScheduleSlots(doctorId),
      queryParameters: {
        'mode': mode,
        '_': DateTime.now().millisecondsSinceEpoch,
      },
    );
    final data = res.data ?? {};
    assertSuccess(data);

    final schedule = <String, DaySlotsModel>{};
    for (final item in (data['days'] as List?) ?? []) {
      if (item is! Map) continue;
      final dayMeta = Map<String, dynamic>.from(item);
      final key = _dayKey(dayMeta);
      if (key == null) continue;
      schedule[key] = _daySlotsFromMeta(dayMeta, key, mode);
      final legacy = dayMeta['slotDate']?.toString();
      if (legacy != null && legacy.isNotEmpty && legacy != key) {
        schedule[legacy] = schedule[key]!;
      }
    }
    return schedule;
  }

  Future<DaySlotsModel> fetchSlots(String doctorId, String slotDate, {String mode = 'offline'}) async {
    final schedule = await fetchDoctorSchedule(doctorId, mode: mode);
    return schedule[slotDate] ??
        DaySlotsModel(date: slotDate, displayDate: slotDate, slots: const []);
  }

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
  }) async {
    final patientJson = (patient ?? PatientBookingInfo(name: 'Patient', isSelf: true)).toJson();
    final symptomList = <String>[...(symptoms ?? <String>[])];
    if (notes != null && notes.trim().isNotEmpty) {
      symptomList.add('Note: ${notes.trim()}');
    }
    final resolvedSlotType = inferOpdSlotType(slotTime, slotType);
    final resolvedMode = mode ?? (resolvedSlotType != null ? 'offline' : null);
    final formMap = <String, dynamic>{
      'docId': doctorId,
      'slotDate': slotDate,
      'slotTime': slotTime,
      'symptoms': jsonEncode(symptomList),
      'paymentMethod': paymentMethod,
      if (visitType != null) 'visitType': visitType,
      if (resolvedMode != null) 'mode': resolvedMode,
      if (slotId != null) 'slotId': '$slotId',
      if (resolvedSlotType != null) 'slotType': resolvedSlotType,
      'actualPatient': jsonEncode(patientJson),
      if (hospitalName != null) 'hospitalName': hospitalName,
      if (location != null) 'location': location,
    };
    if (prescription != null) {
      if (prescription.bytes != null) {
        formMap['prescription'] = MultipartFile.fromBytes(
          prescription.bytes!,
          filename: prescription.name,
        );
      } else if (prescription.path != null) {
        formMap['prescription'] = await MultipartFile.fromFile(
          prescription.path!,
          filename: prescription.name,
        );
      }
    }
    final form = FormData.fromMap(formMap);
    final res = await _api.dio.post<Map<String, dynamic>>(
      ApiConfig.bookAppointment,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = Map<String, dynamic>.from(res.data ?? {});
    assertSuccess(data, 'Booking failed');
    // Use book response only — avoid slow second GET /appointments (full list).
    data['bookingId'] = data['bookingId'] ?? data['booking_id'];
    data['tokenNumber'] = data['tokenNumber'] ?? data['token_number'];
    data['queuePosition'] = data['queuePosition'] ?? data['queue_position'];
    return data;
  }

  Future<void> cancel(String appointmentId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.cancelAppointment,
      data: {'appointmentId': int.tryParse(appointmentId) ?? appointmentId},
    );
    assertSuccess(res.data ?? {}, 'Cancel failed');
  }
}
