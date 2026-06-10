import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<void> openReportBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  final path = '${dir.path}/$safeName';
  final file = File(path);
  await file.writeAsBytes(bytes);

  final result = await OpenFilex.open(
    path,
    type: mimeType,
  );
  if (result.type != ResultType.done) {
    throw Exception(result.message.isNotEmpty ? result.message : 'Could not open report');
  }
}
