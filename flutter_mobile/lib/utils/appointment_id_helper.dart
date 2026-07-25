import 'dart:math';

/// Matches frontend Appointment.jsx generateAppointmentId().
String generateDisplayAppointmentId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(100000);
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final letter = letters[Random().nextInt(letters.length)];
  return 'APT-$letter${timestamp.toString().substring(timestamp.toString().length - 6)}${random.toString().padLeft(5, '0')}';
}

String formatTokenLabel(int? tokenNumber) {
  if (tokenNumber == null || tokenNumber <= 0) return '';
  return 'Token #$tokenNumber';
}
