import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/theme_context.dart';

enum HomeSearchScope {
  all,
  doctors,
  hospitals,
  specialities,
  labsPharmacy,
}

extension HomeSearchScopeX on HomeSearchScope {
  bool get allowsDoctors =>
      this == HomeSearchScope.all || this == HomeSearchScope.doctors;

  bool get allowsSpecialities =>
      this == HomeSearchScope.all || this == HomeSearchScope.specialities;

  bool get allowsServices =>
      this == HomeSearchScope.all ||
      this == HomeSearchScope.hospitals ||
      this == HomeSearchScope.labsPharmacy ||
      this == HomeSearchScope.doctors;

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      HomeSearchScope.all => l10n.homeSearchScopeAll,
      HomeSearchScope.doctors => l10n.homeSearchScopeDoctors,
      HomeSearchScope.hospitals => l10n.homeSearchScopeHospitals,
      HomeSearchScope.specialities => l10n.homeSearchScopeSpecialities,
      HomeSearchScope.labsPharmacy => l10n.homeSearchScopeLabsPharmacy,
    };
  }
}

Future<HomeSearchScope?> showHomeSearchScopeSheet(
  BuildContext context, {
  required HomeSearchScope current,
}) {
  return showModalBottomSheet<HomeSearchScope>(
    context: context,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ctx.l10n.homeSearchScopeTitle,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ctx.l10n.homeSearchScopeSubtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HomeSearchScope.values.map((scope) {
                  final selected = scope == current;
                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Text(scope.label(ctx)),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : context.primaryText,
                    ),
                    selectedColor: AppColors.specCircleFill,
                    backgroundColor: context.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                    side: BorderSide(
                      color: selected
                          ? AppColors.specCircleFill
                          : context.borderColor,
                    ),
                    onSelected: (_) => Navigator.pop(ctx, scope),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
