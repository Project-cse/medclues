import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hospital_detail_model.dart';
import '../models/hospital_model.dart';
import '../services/hospital_service.dart';
import '../services/api_service.dart';

final hospitalServiceProvider = Provider<HospitalService>((ref) {
  return HospitalService(ref.watch(apiServiceProvider));
});

final hospitalsListProvider = FutureProvider.autoDispose<List<HospitalModel>>((ref) {
  return ref.watch(hospitalServiceProvider).fetchAll();
});

final hospitalDetailProvider = FutureProvider.autoDispose.family<HospitalDetailModel, String>((ref, id) {
  return ref.watch(hospitalServiceProvider).fetchDetails(id);
});
