import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, text, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    Widget child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16));

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.signInButton,
            foregroundColor: Colors.white,
            minimumSize: Size(fullWidth ? double.infinity : 0, AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(fullWidth ? double.infinity : 0, AppDimensions.buttonHeight),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
          ),
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: Size(fullWidth ? double.infinity : 0, AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(onPressed: disabled ? null : onPressed, child: child),
    };

    return Opacity(opacity: disabled && !loading ? 0.5 : 1, child: button);
  }
}
