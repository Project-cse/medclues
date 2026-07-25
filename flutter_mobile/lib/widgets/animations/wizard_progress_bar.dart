import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../brand/medclues_palette.dart';

/// Top-docked wizard progress — Teal bar grows via AnimatedContainer per step.
class WizardProgressBar extends StatelessWidget {
  const WizardProgressBar({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.labels,
  });

  final int step;
  final int totalSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / totalSteps;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(totalSteps, (i) {
              final active = i <= step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: MedcluesPalette.emphasized,
                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? MedcluesPalette.medicalTeal : MedcluesPalette.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Step ${step + 1} of $totalSteps',
            style: GoogleFonts.poppins(fontSize: 12, color: MedcluesPalette.softSlate),
          ),
          Text(
            labels[step.clamp(0, labels.length - 1)],
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MedcluesPalette.deepNavy,
            ),
          ).animate(key: ValueKey(step)).fadeIn(duration: 300.ms).slideX(begin: 0.04, end: 0),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 420),
              curve: MedcluesPalette.emphasized,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: MedcluesPalette.slate200,
                color: MedcluesPalette.medicalTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
