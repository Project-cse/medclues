import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _online(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}

/// Emits true when the device reports a usable network path.
final connectivityOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    yield _online(await connectivity.checkConnectivity());
  } catch (_) {
    yield true;
  }
  await for (final results in connectivity.onConnectivityChanged) {
    yield _online(results);
  }
});
