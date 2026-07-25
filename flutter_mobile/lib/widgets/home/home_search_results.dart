import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../routes/route_names.dart';

/// Matches mobile/components/home/HomeSearchResults.tsx
class HomeSearchResultItem {
  const HomeSearchResultItem._({
    required this.type,
    required this.label,
    this.route,
    this.tab,
    this.filterKey,
    this.doctor,
  });

  factory HomeSearchResultItem.service(String label, String route, {String? tab}) {
    return HomeSearchResultItem._(type: 'service', label: label, route: route, tab: tab);
  }

  factory HomeSearchResultItem.speciality(String label, String filterKey) {
    return HomeSearchResultItem._(
      type: 'speciality',
      label: label,
      filterKey: filterKey,
      route: RouteNames.doctors,
    );
  }

  factory HomeSearchResultItem.doctor(DoctorModel doctor) {
    return HomeSearchResultItem._(type: 'doctor', label: doctor.name, doctor: doctor);
  }

  final String type;
  final String label;
  final String? route;
  final String? tab;
  final String? filterKey;
  final DoctorModel? doctor;

  String? get subtitle {
    if (type == 'doctor') return doctor?.specialization;
    return type;
  }
}

class HomeSearchResults extends StatelessWidget {
  const HomeSearchResults({
    super.key,
    required this.results,
    required this.loading,
    required this.onSelect,
  });

  final List<HomeSearchResultItem> results;
  final bool loading;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator(color: AppColors.specCircleFill)),
      );
    }
    if (results.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: results.asMap().entries.map((e) {
          final item = e.value;
          return InkWell(
            onTap: () {
              onSelect();
              _navigate(context, item);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: e.key < results.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.inputBorder))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(_iconFor(item.type), size: 18, color: AppColors.specCircleFill),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.subtitle != null)
                          Text(
                            item.subtitle!,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'doctor':
        return Icons.person_outline;
      case 'speciality':
        return Icons.favorite_outline;
      default:
        return Icons.grid_view;
    }
  }

  void _navigate(BuildContext context, HomeSearchResultItem item) {
    switch (item.type) {
      case 'doctor':
        context.push('/doctors/${item.doctor!.id}');
        break;
      case 'speciality':
        context.push('${RouteNames.doctors}?speciality=${Uri.encodeComponent(item.filterKey!)}');
        break;
      case 'service':
        if (item.route == null) return;
        if (item.tab != null) {
          context.push('${item.route}?tab=${item.tab}');
        } else {
          context.push(item.route!);
        }
        break;
    }
  }
}
