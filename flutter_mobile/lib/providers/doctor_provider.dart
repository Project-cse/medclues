import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import '../utils/speciality_match.dart';
import 'service_providers.dart';

final selectedSpecialityProvider = StateProvider<String?>((_) => null);

final allDoctorsProvider = FutureProvider<List<DoctorModel>>((ref) {
  ref.keepAlive();
  return ref.watch(doctorRepositoryProvider).getDoctors();
});

final doctorsListProvider = FutureProvider.autoDispose<List<DoctorModel>>((ref) async {
  final speciality = ref.watch(selectedSpecialityProvider);
  final all = await ref.watch(allDoctorsProvider.future);
  if (speciality != null && speciality.isNotEmpty) {
    final key = canonicalSpecialityKey(speciality) ?? speciality;
    return all.where((d) => matchesSpeciality(d.specialization, key)).toList();
  }
  return all;
});

/// Home top doctors — top 10 by rating, one per specialty when possible.
final topDoctorsProvider = FutureProvider<List<DoctorModel>>((ref) async {
  ref.keepAlive();
  final all = await ref.watch(allDoctorsProvider.future);
  return DoctorService.pickTopDoctors(all, limit: DoctorService.homeTopDoctorLimit);
});

final doctorDetailProvider = FutureProvider.autoDispose.family<DoctorModel, String>((ref, id) async {
  final allAsync = ref.watch(allDoctorsProvider);
  if (allAsync.hasValue) {
    for (final d in allAsync.value!) {
      if (d.id == id) return d;
    }
  }
  return ref.watch(doctorRepositoryProvider).getDoctor(id);
});

final doctorSearchProvider =
    FutureProvider.autoDispose.family<List<DoctorModel>, String>((ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return [];
  try {
    return await ref.watch(doctorRepositoryProvider).search(q);
  } catch (_) {
    final all = await ref.watch(allDoctorsProvider.future);
    final lower = q.toLowerCase();
    return all
        .where((d) =>
            d.name.toLowerCase().contains(lower) ||
            d.specialization.toLowerCase().contains(lower))
        .toList();
  }
});
