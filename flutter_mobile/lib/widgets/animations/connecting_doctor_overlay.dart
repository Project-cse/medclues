import 'package:flutter/material.dart';

import 'signal_pulse_painter.dart';

/// Video consult pre-connect HUD — canvas signal pulses + doctor portrait mask.
class ConnectingDoctorOverlay extends StatelessWidget {
  const ConnectingDoctorOverlay({super.key, this.doctorName});

  final String? doctorName;

  @override
  Widget build(BuildContext context) {
    return MedcluesConnectingHud(doctorName: doctorName);
  }
}
