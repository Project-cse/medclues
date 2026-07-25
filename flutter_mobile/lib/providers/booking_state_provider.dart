import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/doctor_model.dart';

import '../models/patient_booking_info.dart';

class BookingDraft {
  final DoctorModel doctor;

  final String date;

  final String time;

  final String visitType;

  final String paymentMethod;

  final String? notes;

  final String? appointmentId;

  /// Short unique ID for receipt QR (e.g. BK8X4P2).

  final String? bookingId;

  final String? publicId;

  final int? tokenNumber;

  final int? queuePosition;

  final PatientBookingInfo patient;

  final String? hospitalName;

  final String? location;

  final String? roomNo;

  const BookingDraft({
    required this.doctor,
    required this.date,
    required this.time,
    required this.patient,
    this.visitType = 'In-Person',
    this.paymentMethod = 'payOnVisit',
    this.notes,
    this.appointmentId,
    this.bookingId,
    this.publicId,
    this.tokenNumber,
    this.queuePosition,
    this.hospitalName,
    this.location,
    this.roomNo,
  });

  BookingDraft copyWith({
    DoctorModel? doctor,
    String? date,
    String? time,
    String? visitType,
    String? paymentMethod,
    String? notes,
    String? appointmentId,
    String? bookingId,
    String? publicId,
    int? tokenNumber,
    int? queuePosition,
    PatientBookingInfo? patient,
    String? hospitalName,
    String? location,
    String? roomNo,
  }) {
    return BookingDraft(
      doctor: doctor ?? this.doctor,
      date: date ?? this.date,
      time: time ?? this.time,
      visitType: visitType ?? this.visitType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      appointmentId: appointmentId ?? this.appointmentId,
      bookingId: bookingId ?? this.bookingId,
      publicId: publicId ?? this.publicId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      queuePosition: queuePosition ?? this.queuePosition,
      patient: patient ?? this.patient,
      hospitalName: hospitalName ?? this.hospitalName,
      location: location ?? this.location,
      roomNo: roomNo ?? this.roomNo,
    );
  }
}

final bookingDraftProvider = StateProvider<BookingDraft?>((_) => null);

final bookingPatientProvider = StateProvider<PatientBookingInfo?>((_) => null);

/// After a successful book, pin this appointment to the front of the home floating bar.
final lastBookedAppointmentIdProvider = StateProvider<String?>((_) => null);
