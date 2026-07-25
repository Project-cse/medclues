import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_healthcare_theme.dart';

class PremiumPatientFormField extends StatelessWidget {
  const PremiumPatientFormField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: PremiumHealthcareTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: PremiumHealthcareTheme.fieldHeight,
              decoration: BoxDecoration(
                color: PremiumHealthcareTheme.white(context),
                borderRadius: BorderRadius.circular(PremiumHealthcareTheme.fieldRadius),
                border: Border.all(color: PremiumHealthcareTheme.border(context)),
                boxShadow: PremiumHealthcareTheme.fieldShadow(context),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                readOnly: readOnly,
                onTap: onTap,
                inputFormatters: inputFormatters,
                onChanged: (v) {
                  state.didChange(v);
                  onChanged?.call(v);
                },
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: PremiumHealthcareTheme.text(context),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: icon != null
                      ? Icon(icon, size: 20, color: PremiumHealthcareTheme.secondaryBlue)
                      : null,
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: PremiumHealthcareTheme.textSecondary(context),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PremiumPatientDropdownField extends StatelessWidget {
  const PremiumPatientDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: PremiumHealthcareTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: PremiumHealthcareTheme.fieldHeight,
          decoration: BoxDecoration(
            color: PremiumHealthcareTheme.white(context),
            borderRadius: BorderRadius.circular(PremiumHealthcareTheme.fieldRadius),
            border: Border.all(color: PremiumHealthcareTheme.border(context)),
            boxShadow: PremiumHealthcareTheme.fieldShadow(context),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                const SizedBox(width: 12),
                Icon(icon, size: 20, color: PremiumHealthcareTheme.secondaryBlue),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: PremiumHealthcareTheme.textSecondary(context)),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: PremiumHealthcareTheme.text(context),
                    ),
                    items: items
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PremiumContinueButton extends StatelessWidget {
  const PremiumContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null && !loading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: PremiumHealthcareTheme.ctaHeight,
      decoration: BoxDecoration(
        gradient: active ? PremiumHealthcareTheme.ctaGradient : null,
        color: active ? null : PremiumHealthcareTheme.border(context),
        borderRadius: BorderRadius.circular(PremiumHealthcareTheme.ctaRadius),
        boxShadow: active ? PremiumHealthcareTheme.ctaShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active ? onPressed : null,
          borderRadius: BorderRadius.circular(PremiumHealthcareTheme.ctaRadius),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : PremiumHealthcareTheme.textSecondary(context),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
