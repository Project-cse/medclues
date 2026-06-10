import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/storage_helper.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/doctor_repository.dart';
import '../repositories/patient_repository.dart';
import '../repositories/speciality_repository.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import '../services/doctor_service.dart';
import '../services/notification_service.dart';
import '../services/patient_service.dart';
import '../services/health_record_service.dart';
import '../services/payment_service.dart';
import '../services/speciality_service.dart';
import '../services/consultation_service.dart';
import '../services/telegram_link_service.dart';
import '../services/api_service.dart';
import '../features/emergency/services/emergency_api_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(apiServiceProvider)));
final doctorServiceProvider = Provider<DoctorService>((ref) => DoctorService(ref.watch(apiServiceProvider)));
final specialityServiceProvider = Provider<SpecialityService>((ref) => SpecialityService(ref.watch(apiServiceProvider)));
final patientServiceProvider = Provider<PatientService>((ref) => PatientService(ref.watch(apiServiceProvider)));
final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService(ref.watch(apiServiceProvider)));
final emergencyApiServiceProvider = Provider<EmergencyApiService>(
  (ref) => EmergencyApiService(ref.watch(apiServiceProvider)),
);
final healthRecordServiceProvider = Provider<HealthRecordService>((ref) => HealthRecordService(ref.watch(apiServiceProvider)));
final consultationServiceProvider = Provider<ConsultationService>((ref) => ConsultationService(ref.watch(apiServiceProvider)));
final telegramLinkServiceProvider = Provider<TelegramLinkService>(
  (ref) => TelegramLinkService(ref.watch(apiServiceProvider)),
);

final appointmentServiceProvider = Provider<AppointmentService>((ref) => AppointmentService(
      ref.watch(apiServiceProvider),
    ));
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref.watch(appointmentServiceProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      ref.watch(authServiceProvider),
      ref.watch(storageHelperProvider),
    ));
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) => DoctorRepository(ref.watch(doctorServiceProvider)));
final specialityRepositoryProvider = Provider<SpecialityRepository>((ref) => SpecialityRepository(ref.watch(specialityServiceProvider)));
final patientRepositoryProvider = Provider<PatientRepository>((ref) => PatientRepository(ref.watch(patientServiceProvider)));
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) => AppointmentRepository(ref.watch(appointmentServiceProvider)));
