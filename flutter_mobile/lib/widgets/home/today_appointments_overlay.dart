import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/appointment_status_utils.dart';
import '../../utils/date_formatter.dart';
import '../../utils/theme_context.dart';
import '../appointments/live_queue_panel.dart';
import '../common/appointment_status_chip.dart';

class TodayAppointmentsOverlay extends ConsumerStatefulWidget {
  const TodayAppointmentsOverlay({super.key});

  @override
  ConsumerState<TodayAppointmentsOverlay> createState() =>
      _TodayAppointmentsOverlayState();
}

class _TodayAppointmentsOverlayState
    extends ConsumerState<TodayAppointmentsOverlay> {
  bool _collapsed = false;
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _page = 0;
  int _carouselLength = 0;
  String? _firstId;

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _configureCarousel(int length, {String? firstId}) {
    final lengthChanged = _carouselLength != length;
    final orderChanged = firstId != null && firstId != _firstId;
    _carouselLength = length;
    _firstId = firstId;
    if (lengthChanged || orderChanged) {
      _page = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
    _startAutoSlide(length);
  }

  void _startAutoSlide(int length) {
    _autoSlideTimer?.cancel();
    if (length <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients || _collapsed) return;
      _page = (_page + 1) % length;
      _pageController.animateToPage(
        _page,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseForUserSwipe(int length) {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _startAutoSlide(length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayAppointmentsProvider);

    return todayAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _configureCarousel(0);
          });
          return const SizedBox.shrink();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _configureCarousel(list.length, firstId: list.first.id);
          }
        });
        return _collapsed ? _collapsedPill(list) : _expandedCard(list);
      },
    );
  }

  Widget _collapsedPill(List<AppointmentModel> list) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        elevation: 4,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(999),
        color: AppColors.logoTeal,
        child: InkWell(
          onTap: () => setState(() => _collapsed = false),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_available_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  l10n.todayAppointmentsCount(list.length),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandedCard(List<AppointmentModel> list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SizedBox(
        height: 118,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (_) {
            if (list.length > 1) _pauseForUserSwipe(list.length);
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: list.length,
            onPageChanged: (value) => _page = value,
            itemBuilder: (context, index) =>
                _appointmentCard(list, list[index], index),
          ),
        ),
      ),
    );
  }

  Widget _appointmentCard(
    List<AppointmentModel> list,
    AppointmentModel appointment,
    int index,
  ) {
    final l10n = context.l10n;
    final liveQueue = ref.watch(liveQueueProvider(appointment.id)).valueOrNull;
    final liveLifecycle =
        (liveQueue?.receptionStatus ?? '').toUpperCase() == 'READY_FOR_DOCTOR'
            ? 'CHECKED_IN'
            : liveQueue?.lifecycleStatus;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        color: context.cardColor,
        child: InkWell(
          onTap: () {
            if (appointment.canConfirmTomorrowRescheduleEffective ||
                appointment.isMissed) {
              context.push('/appointments/${appointment.id}');
            } else {
              context.go(RouteNames.appointments);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.logoTeal.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                        appointment.isMissed
                            ? Icons.event_busy_rounded
                            : Icons.calendar_today_rounded,
                        size: 14,
                        color: appointment.isMissed
                            ? const Color(0xFFEA580C)
                            : AppColors.logoTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.isMissed
                            ? 'Missed — reschedule for tomorrow?'
                            : (list.every((a) => isAppointmentToday(a.slotDate))
                                ? l10n.todayAppointmentsTitle
                                : l10n.navAppointments),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.primaryText,
                        ),
                      ),
                    ),
                    Text(
                      '${index + 1}/${list.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.logoTeal,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => setState(() => _collapsed = true),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: context.secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.doctorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.primaryText,
                            ),
                          ),
                          Text(
                            'Patient: ${appointment.patientLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.logoTeal,
                            ),
                          ),
                          Text(
                            '${DateFormatter.formatSlotDate(appointment.slotDate)} · ${DateFormatter.displayTime(appointment.slotTime)}',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: context.secondaryText),
                          ),
                          LiveQueuePanel(
                              appointment: appointment,
                              mode: LiveQueuePanelMode.compact),
                        ],
                      ),
                    ),
                    AppointmentStatusChip(
                      appointment: appointment,
                      compact: true,
                      isNextUp: liveQueue?.isNextUp == true,
                      lifecycleStatus: liveLifecycle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
