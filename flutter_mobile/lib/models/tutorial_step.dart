import 'package:flutter/material.dart';

class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    required this.icon,
    this.targetKey,
    this.highlightLabel,
  });

  final String title;
  final String body;
  final IconData icon;
  final GlobalKey? targetKey;
  final String? highlightLabel;
}
