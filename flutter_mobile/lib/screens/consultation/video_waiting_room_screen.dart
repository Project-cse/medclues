import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/app_permissions_service.dart';
import '../../services/consultation_service.dart';
import '../../utils/app_exception.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';

/// Smart waiting room — request call, poll until doctor accepts, then join Agora room.
class VideoWaitingRoomScreen extends ConsumerStatefulWidget {
  const VideoWaitingRoomScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<VideoWaitingRoomScreen> createState() => _VideoWaitingRoomScreenState();
}

class _VideoWaitingRoomScreenState extends ConsumerState<VideoWaitingRoomScreen> {
  CallSessionStatus? _session;
  String? _error;
  bool _requesting = true;
  bool _navigatingToVideo = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (!kIsWeb) {
      try {
        await AppPermissionsService.requireVideoConsult();
      } on VideoConsultPermissionException catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _requesting = false;
        });
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _requesting = false;
        });
        return;
      }
    }

    try {
      final session = await ref.read(consultationServiceProvider).requestCall(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _requesting = false;
      });
      if (session.canJoin) {
        _goToVideo();
        return;
      }
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _formatCallRequestError(e);
        _requesting = false;
      });
    }
  }

  String _formatCallRequestError(Object e) {
    if (e is AppException && e.statusCode == 404) {
      return 'Video calling is not available on the server yet. '
          'Please try again after the app backend is updated.';
    }
    final msg = e.toString().replaceFirst('Exception: ', '');
    if (msg.toLowerCase() == 'not found') {
      return 'Video calling service is unavailable. Please try again in a few minutes.';
    }
    return msg;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final session = await ref.read(consultationServiceProvider).fetchCallStatus(widget.appointmentId);
      if (!mounted) return;
      setState(() => _session = session);
      if (session.canJoin) {
        _pollTimer?.cancel();
        _goToVideo();
      } else if (session.status == 'rejected' || session.status == 'busy' || session.status == 'cancelled') {
        _pollTimer?.cancel();
      }
    } catch (_) {}
  }

  Future<void> _goToVideo() async {
    if (!mounted || _navigatingToVideo) return;
    _navigatingToVideo = true;
    _pollTimer?.cancel();

    if (!kIsWeb) {
      try {
        await AppPermissionsService.requireVideoConsult();
      } on VideoConsultPermissionException catch (e) {
        _navigatingToVideo = false;
        if (mounted) setState(() => _error = e.toString());
        return;
      } catch (e) {
        _navigatingToVideo = false;
        if (mounted) setState(() => _error = e.toString());
        return;
      }
    }

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    context.pushReplacement('/video-consult/${widget.appointmentId}');
  }

  Future<void> _cancel() async {
    try {
      await ref.read(consultationServiceProvider).cancelCallRequest(widget.appointmentId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString());
    }
  }

  String _statusLabel(CallSessionStatus? s, AppLocalizations l10n) {
    if (s == null) return l10n.videoConnecting;
    switch (s.status) {
      case 'requested':
      case 'ringing':
        return l10n.videoWaitingDoctor;
      case 'accepted':
      case 'ongoing':
        return l10n.videoConnecting;
      case 'rejected':
        return 'Doctor declined';
      case 'busy':
        return 'Doctor is busy';
      default:
        return s.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appt = ref.watch(appointmentDetailProvider(widget.appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorVideoConsult, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: appt.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (a) {
          if (_requesting) {
            return const Center(child: AppLoader());
          }
          if (_error != null) {
            return _messageCard(
              icon: Icons.error_outline,
              title: _error!,
              action: AppButton(label: l10n.videoGoBack, onPressed: () => context.pop()),
            );
          }

          final session = _session;
          final terminal = session != null &&
              (session.status == 'rejected' || session.status == 'busy' || session.status == 'cancelled');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.videoConsult,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.doctorName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (a.specialization.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(a.specialization, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${a.slotDate} · ${a.slotTime}',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!terminal) ...[
                  const Center(child: CircularProgressIndicator(color: AppColors.logoTeal)),
                  const SizedBox(height: 20),
                ],
                Text(
                  _statusLabel(session, l10n),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  terminal
                      ? (session!.rejectReason ?? 'Please try again later or contact the clinic.')
                      : 'Ringing the doctor… You will join automatically when they accept.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (a.tokenNumber != null && a.tokenNumber! > 0) ...[
                  const SizedBox(height: 20),
                  _infoChip(Icons.confirmation_number_outlined, 'Token #${a.tokenNumber}'),
                ],
                if (session != null && session.queuePosition != null && session.queuePosition! > 0) ...[
                  const SizedBox(height: 10),
                  _infoChip(Icons.people_outline, 'Queue position: ${session.queuePosition}'),
                ],
                const SizedBox(height: 32),
                if (terminal)
                  AppButton(
                    label: l10n.videoGoBack,
                    onPressed: () => context.pop(),
                  )
                else
                  AppButton(
                    label: 'Cancel request',
                    variant: AppButtonVariant.secondary,
                    onPressed: _cancel,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.logoTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.logoTeal),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _messageCard({required IconData icon, required String title, required Widget action}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 15)),
          const SizedBox(height: 24),
          action,
        ],
      ),
    );
  }
}
