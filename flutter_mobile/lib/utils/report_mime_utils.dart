/// MIME types for health reports (PDF, Word, WPS, images).
class ReportMimeUtils {
  ReportMimeUtils._();

  static String extensionFromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  static String? mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'wps':
        return 'application/vnd.ms-works';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }

  static String? mimeFromFileName(String fileName) {
    return mimeFromExtension(extensionFromFileName(fileName));
  }

  static String resolveMimeType({
    required String fileName,
    String? contentType,
    String? fileType,
  }) {
    final header = (contentType ?? '').split(';').first.trim().toLowerCase();
    if (header.isNotEmpty &&
        header != 'application/octet-stream' &&
        header != 'binary/octet-stream') {
      return header;
    }

    final fromName = mimeFromFileName(fileName);
    if (fromName != null) return fromName;

    final ft = (fileType ?? '').toLowerCase();
    if (ft.isNotEmpty) {
      final fromType = mimeFromExtension(ft == 'vnd.openxmlformats-officedocument.wordprocessingml.document'
          ? 'docx'
          : ft);
      if (fromType != null) return fromType;
    }

    return 'application/octet-stream';
  }

  static String ensureExtension(String fileName, {String? fileType, String? contentType}) {
    if (extensionFromFileName(fileName).isNotEmpty) return fileName;

    final ft = (fileType ?? '').toLowerCase();
    if (ft == 'pdf' || (contentType ?? '').contains('pdf')) return '$fileName.pdf';
    if (ft == 'docx' || ft.contains('wordprocessingml')) return '$fileName.docx';
    if (ft == 'doc' || ft == 'msword') return '$fileName.doc';
    if (ft == 'wps') return '$fileName.wps';
    if (ft == 'png') return '$fileName.png';
    if (ft == 'jpg' || ft == 'jpeg') return '$fileName.jpg';

    return '$fileName.pdf';
  }

  static String sanitizeFileName(String fileName) {
    final trimmed = fileName.trim().isEmpty ? 'report' : fileName.trim();
    return trimmed.replaceAll(RegExp(r'[^\w.\-]'), '_');
  }
}
