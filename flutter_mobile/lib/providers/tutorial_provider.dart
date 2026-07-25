import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set to true briefly when user taps "Take app tour" from Help.
final tutorialReplayProvider = StateProvider<bool>((ref) => false);
