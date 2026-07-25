import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/speciality_model.dart';
import 'service_providers.dart';

final specialitiesProvider = FutureProvider.autoDispose<List<SpecialityModel>>((ref) {
  return ref.watch(specialityRepositoryProvider).getAll();
});
