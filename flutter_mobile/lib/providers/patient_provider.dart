import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_model.dart';
import 'service_providers.dart';

final patientProfileProvider = FutureProvider.autoDispose<PatientModel>((ref) {
  return ref.watch(patientRepositoryProvider).getProfile();
});
