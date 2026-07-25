import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_record_service.dart';
import 'service_providers.dart';

final healthRecordsProvider = FutureProvider.autoDispose<List<HealthRecordItem>>((ref) {
  // Keep cached result briefly so Home → Records does not flash blank/loading forever.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(healthRecordServiceProvider).fetchAll();
});
