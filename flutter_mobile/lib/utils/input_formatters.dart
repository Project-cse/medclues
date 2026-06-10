import 'package:flutter/services.dart';

class InputFormatters {
  InputFormatters._();

  static final name = [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
    LengthLimitingTextInputFormatter(50),
  ];

  static final doctorName = [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
    LengthLimitingTextInputFormatter(60),
  ];

  static final emergencyName = [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
    LengthLimitingTextInputFormatter(50),
  ];

  static final digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  static final phone = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  static final otp = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ];

  static final address = [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ,\-/]')),
    LengthLimitingTextInputFormatter(250),
  ];

  static final reportTitle = [
    LengthLimitingTextInputFormatter(100),
  ];

  static final appointmentReason = [
    LengthLimitingTextInputFormatter(500),
  ];
}
