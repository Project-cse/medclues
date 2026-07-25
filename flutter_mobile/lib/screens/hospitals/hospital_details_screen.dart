import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/hospital_provider.dart';
import '../../utils/hospital_stats.dart';
import '../../utils/image_url_helper.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../../widgets/healthcare/hospital_contact_actions.dart';
import '../../widgets/healthcare/premium_hospital_widgets.dart';

/// Hospital details — premium layout with live API data only.
class HospitalDetailsScreen extends ConsumerWidget {
  const HospitalDetailsScreen({super.key, required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(hospitalDetailProvider(hospitalId));

    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background(context),
      appBar: const PremiumHospitalAppBar(),
      body: detail.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: PremiumHealthcareTheme.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(hospitalDetailProvider(hospitalId)),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: PremiumHealthcareTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (d) {
          final h = d.hospital;
          final doctors = d.doctors;
          final stats = HospitalComputedStats.from(h, doctors);
          final subtitle = h.specialization?.trim();
          precacheImage(const AssetImage(kHospitalBuildingAsset), context);

          return RefreshIndicator(
            color: PremiumHealthcareTheme.primaryBlue,
            onRefresh: () async => ref.invalidate(hospitalDetailProvider(hospitalId)),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: PremiumHospitalHeroCard(
                    badge: h.displayBadge,
                    name: h.name,
                    subtitle: (subtitle != null && subtitle.isNotEmpty) ? subtitle : null,
                    address: h.address,
                    phone: h.contact,
                    backgroundImageUrl: resolveImageUrl(h.backgroundImage),
                  ),
                ),
                SliverToBoxAdapter(
                  child: HospitalContactActions(
                    hospitalName: h.name,
                    address: h.address,
                    phone: h.contact,
                    mapsLink: h.mapsLink,
                  ),
                ),
                SliverToBoxAdapter(child: PremiumHospitalStatsRow(stats: stats)),
                SliverToBoxAdapter(
                  child: PremiumDoctorsSectionHeader(
                    count: doctors.length,
                    showViewAll: doctors.isNotEmpty,
                  ),
                ),
                if (doctors.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PremiumHealthcareTheme.horizontalPadding,
                      ),
                      child: Text(
                        'No doctors listed for this hospital yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: PremiumHealthcareTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = doctors[index];
                        return PremiumHospitalDoctorCard(
                          doctor: doc,
                          onBook: doc.isBookable
                              ? () => context.push('/booking/patient/${doc.id}')
                              : null,
                        );
                      },
                      childCount: doctors.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: PremiumHospitalTrustBanner()),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          );
        },
      ),
    );
  }
}
