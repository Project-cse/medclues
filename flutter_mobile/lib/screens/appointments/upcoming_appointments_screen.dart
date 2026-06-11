import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/calendar_helper.dart';
import '../../utils/theme_context.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/cards/appointment_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/list_pagination.dart';
import '../../widgets/skeleton/appointment_card_skeleton.dart';

/// Matches mobile/app/(patient)/appointments.tsx
class UpcomingAppointmentsScreen extends ConsumerStatefulWidget {
  const UpcomingAppointmentsScreen({super.key});

  @override
  ConsumerState<UpcomingAppointmentsScreen> createState() => _UpcomingAppointmentsScreenState();
}

class _UpcomingAppointmentsScreenState extends ConsumerState<UpcomingAppointmentsScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tab = ref.watch(appointmentsTabProvider);
    final providers = [
      ref.watch(upcomingAppointmentsProvider),
      ref.watch(pastAppointmentsProvider),
      ref.watch(cancelledAppointmentsProvider),
    ];
    final async = providers[tab];
    final canCancel = tab == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointmentsMyTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _tabs(tab),
          Expanded(child: _list(async, canCancel: canCancel)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: () => context.push(RouteNames.doctors),
            style: FilledButton.styleFrom(
              backgroundColor: context.isDark ? context.cs.primary : AppColors.brandNavy,
              foregroundColor: context.isDark ? context.cs.onPrimary : Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n.bookingBookAppointment,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.isDark ? context.cs.onPrimary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs(int tab) {
    final labels = [context.l10n.appointmentsUpcoming, context.l10n.appointmentsCompleted, context.l10n.appointmentsCancelled];
    return Row(
      children: List.generate(labels.length, (i) {
        final selected = tab == i;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (tab != i) setState(() => _page = 0);
              ref.read(appointmentsTabProvider.notifier).state = i;
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.specCircleFill : context.secondaryText,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    height: 3,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.specCircleFill,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(height: 3),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _list(AsyncValue<List<AppointmentModel>> async, {bool canCancel = false}) {
    return async.when(
      data: (list) {
        if (list.isEmpty) {
          return AppEmptyState(
            title: context.l10n.appointmentsNoTitle,
            subtitle: context.l10n.appointmentsNoSubtitle,
          );
        }
        final totalPages = totalPagesFor(list.length);
        final safePage = _page.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
        if (safePage != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _page = safePage);
          });
        }
        final pageItems = paginateSlice(list, safePage);

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _page = 0);
                  ref.invalidate(upcomingAppointmentsProvider);
                  ref.invalidate(pastAppointmentsProvider);
                  ref.invalidate(cancelledAppointmentsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: pageItems.length,
                  itemBuilder: (_, i) {
                    final a = pageItems[i];
                    return AppointmentCard(
                      appointment: a,
                      showBadge: canCancel,
                      onTap: () => context.push('/appointments/${a.id}'),
                      onAddToCalendar: canCancel
                          ? () async {
                              final ok = await CalendarHelper.addAppointmentToCalendar(a);
                              if (!context.mounted) return;
                              AppSnackbar.show(
                                context,
                                ok
                                    ? context.l10n.appointmentsCalendarAdded
                                    : context.l10n.appointmentsCalendarFailed,
                                success: ok,
                              );
                            }
                          : null,
                      onCancel: canCancel
                          ? () async {
                              try {
                                await cancelAppointmentAndRefresh(ref, a.id);
                                if (!context.mounted) return;
                                setState(() => _page = 0);
                                ref.read(appointmentsTabProvider.notifier).state = 2;
                                AppSnackbar.show(
                                  context,
                                  context.l10n.appointmentsCancelledSuccess,
                                  success: true,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackbar.show(
                                    context,
                                    e.toString().replaceFirst('Exception: ', ''),
                                  );
                                }
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),
            ),
            ListPaginationBar(
              currentPage: safePage,
              totalItems: list.length,
              onPageChanged: (p) => setState(() => _page = p),
            ),
          ],
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 4,
        itemBuilder: (_, __) => const AppointmentCardSkeleton(),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
