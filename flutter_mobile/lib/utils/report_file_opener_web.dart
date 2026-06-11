import 'dart:html' as html;
import 'dart:typed_data';

import 'report_mime_utils.dart';

Future<void> openReportBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
  String? fileType,
}) async {
  final safeName = ReportMimeUtils.sanitizeFileName(
    ReportMimeUtils.ensureExtension(filename, fileType: fileType, contentType: mimeType),
  );
  final type = ReportMimeUtils.resolveMimeType(
    fileName: safeName,
    contentType: mimeType,
    fileType: fileType,
  );

  final blob = html.Blob([bytes], type);
  final url = html.Url.createObjectUrlFromBlob(blob);

  // PDF/images: open in new tab via blob URL (works in Chrome built-in viewer).
  // Word/WPS: trigger download so user opens with desktop app.
  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..rel = 'noopener';
  final isInline = type.startsWith('application/pdf') || type.startsWith('image/');
  if (!isInline) {
    anchor.download = safeName;
  }
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  Future<void>.delayed(const Duration(seconds: 60), () {
    html.Url.revokeObjectUrl(url);
  });
}
