/// Token display helper for appointment queue UI.
String formatTokenLabel(int? tokenNumber) {
  if (tokenNumber == null || tokenNumber <= 0) return '';
  return 'Token #$tokenNumber';
}
