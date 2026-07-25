import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
