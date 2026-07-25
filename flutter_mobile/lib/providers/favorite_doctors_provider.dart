import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/favorite_doctors_service.dart';

final favoriteDoctorsServiceProvider = Provider<FavoriteDoctorsService>((_) {
  return FavoriteDoctorsService();
});

final favoriteDoctorIdsProvider =
    AsyncNotifierProvider<FavoriteDoctorIdsNotifier, Set<String>>(FavoriteDoctorIdsNotifier.new);

class FavoriteDoctorIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    return ref.read(favoriteDoctorsServiceProvider).loadIds();
  }

  Future<bool> toggle(String doctorId) async {
    final next = await ref.read(favoriteDoctorsServiceProvider).toggle(doctorId);
    state = AsyncData(next);
    return next.contains(doctorId);
  }

  bool isFavorite(String doctorId) {
    return state.value?.contains(doctorId) ?? false;
  }
}
