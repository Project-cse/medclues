import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openReportBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
}) async {
  final type = mimeType ?? 'application/pdf';
  final blob = html.Blob([bytes], type);
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Anchor click is more reliable than window.open (popup blockers).
  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..rel = 'noopener';
  if (!type.startsWith('application/pdf') && !type.startsWith('image/')) {
    anchor.download = filename;
  }
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  Future<void>.delayed(const Duration(seconds: 60), () {
    html.Url.revokeObjectUrl(url);
  });
}
