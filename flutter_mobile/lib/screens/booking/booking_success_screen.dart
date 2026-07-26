import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/booking_state_provider.dart';
import '../../routes/route_names.dart';

/// Legacy success route — redirects into the primary confirmation + QR flow.
class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingDraftProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (draft != null) {
        context.go(RouteNames.bookingConfirmation);
      } else {
        context.go(RouteNames.dashboard);
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
