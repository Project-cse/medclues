import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'report_mime_utils.dart';

/// Opens a previously cached report instantly (no network). Returns false when
/// nothing is cached for [cacheKey], so the caller can download it instead.
Future<bool> openCachedReport(
  String cacheKey,
  String filename, {
  String? mimeType,
  String? fileType,
}) async {
  try {
    final safeName = ReportMimeUtils.sanitizeFileName(
      ReportMimeUtils.ensureExtension(filename, fileType: fileType, contentType: mimeType),
    );
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/reports/${_cachePrefix(cacheKey)}$safeName';
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) return false;
    final resolvedMime = ReportMimeUtils.resolveMimeType(
      fileName: safeName,
      contentType: mimeType,
      fileType: fileType,
    );
    final result = await OpenFilex.open(path, type: resolvedMime);
    return result.type == ResultType.done;
  } catch (_) {
    return false;
  }
}

String _cachePrefix(String? cacheKey) =>
    (cacheKey == null || cacheKey.isEmpty) ? '' : '${cacheKey}_';

Future<void> openReportBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
  String? fileType,
  String? cacheKey,
}) async {
  final safeName = ReportMimeUtils.sanitizeFileName(
    ReportMimeUtils.ensureExtension(filename, fileType: fileType, contentType: mimeType),
  );
  final resolvedMime = ReportMimeUtils.resolveMimeType(
    fileName: safeName,
    contentType: mimeType,
    fileType: fileType,
  );

  final dir = await getApplicationDocumentsDirectory();
  final reportsDir = Directory('${dir.path}/reports');
  if (!await reportsDir.exists()) {
    await reportsDir.create(recursive: true);
  }

  // Cache under a stable, record-scoped name so repeat opens are instant.
  final path = '${reportsDir.path}/${_cachePrefix(cacheKey)}$safeName';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);

  var result = await OpenFilex.open(path, type: resolvedMime);
  if (result.type == ResultType.done) return;

  // Let open_filex infer MIME from extension.
  if (resolvedMime != 'application/octet-stream') {
    result = await OpenFilex.open(path);
    if (result.type == ResultType.done) return;
  }

  // Android/iOS chooser — user can pick WPS, Adobe, Google Docs, etc.
  if (result.type == ResultType.noAppToOpen ||
      result.type == ResultType.error ||
      result.type == ResultType.permissionDenied) {
    await Share.shareXFiles(
      [XFile(path, mimeType: resolvedMime, name: safeName)],
      subject: safeName,
      text: 'Open with your PDF or document app',
    );
    return;
  }

  throw Exception(
    result.message.isNotEmpty ? result.message : 'Could not open report',
  );
}
