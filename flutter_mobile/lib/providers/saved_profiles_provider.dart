import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_profile.dart';
import 'service_providers.dart';

final savedProfilesProvider = FutureProvider.autoDispose<List<SavedProfile>>(
  (ref) => ref.watch(savedProfileServiceProvider).fetchAll(),
);
