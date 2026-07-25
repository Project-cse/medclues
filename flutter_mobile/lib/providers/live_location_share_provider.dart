import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/live_location_share_service.dart';

final liveLocationShareServiceProvider = Provider<LiveLocationShareService>((ref) {
  final service = LiveLocationShareService();
  ref.onDispose(service.stop);
  return service;
});

/// Ticks every second while live location sharing is active (for countdown UI).
final liveLocationShareTickProvider = StreamProvider<int>((ref) async* {
  var n = 0;
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield ++n;
  }
});
