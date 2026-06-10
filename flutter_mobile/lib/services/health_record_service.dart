import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class HealthRecordItem {
  const HealthRecordItem({
    required this.id,
    required this.title,
    required this.recordType,
    this.description,
    this.date,
    this.doctorName,
    this.files = const [],
  });

  final String id;
  final String title;
  final String recordType;
  final String? description;
  final String? date;
  final String? doctorName;
  final List<Map<String, dynamic>> files;

  String? get primaryFileUrl {
    for (final f in files) {
      final view = f['viewUrl']?.toString();
      if (view != null && view.isNotEmpty) return view;
      final url = f['url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  factory HealthRecordItem.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    final files = <Map<String, dynamic>>[];
    if (filesRaw is List) {
      for (final f in filesRaw) {
        if (f is Map) files.add(Map<String, dynamic>.from(f));
      }
    }
    return HealthRecordItem(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      title: '${json['title'] ?? 'Report'}',
      recordType: '${json['recordType'] ?? json['record_type'] ?? 'lab_report'}',
      description: json['description']?.toString(),
      date: json['date']?.toString(),
      doctorName: json['doctorName']?.toString() ?? json['doctor_name']?.toString(),
      files: files,
    );
  }
}

class HealthRecordService {
  HealthRecordService(this._api);

  final ApiService _api;

  Future<Uint8List> downloadReportFile(String recordId, {int fileIndex = 0}) async {
    try {
      final res = await _api.dio.get<List<int>>(
        ApiConfig.healthRecordFile(recordId, fileIndex: fileIndex),
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      final contentType = res.headers.value('content-type') ?? '';
      if (contentType.contains('application/json')) {
        throw Exception('Report not found or unavailable');
      }
      final data = res.data;
      if (data == null || data.isEmpty) {
        throw Exception('Report file is empty or unavailable');
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw Exception('Report not found. Try uploading again.');
      }
      if (status == 502) {
        final msg = _errorMessageFromBody(e.response?.data);
        throw Exception(msg ?? 'Could not load report from storage');
      }
      rethrow;
    }
  }

  String? _errorMessageFromBody(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is List<int> || data is Uint8List) return null;
    return null;
  }

  Future<String> fetchViewUrl(String recordId, {int fileIndex = 0}) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiConfig.healthRecordViewUrl(recordId, fileIndex: fileIndex),
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Could not load report');
    final url = data['viewUrl']?.toString() ?? '';
    if (url.isEmpty) throw Exception('No view URL returned');
    return url;
  }

  Future<List<HealthRecordItem>> fetchAll() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.healthRecords);
    final data = res.data ?? {};
    assertSuccess(data);
    return unwrapList(data, ['records', 'healthRecords', 'data'])
        .map(HealthRecordItem.fromJson)
        .toList();
  }

  Future<void> upload({
    required String userId,
    required String docId,
    required String doctorName,
    required String title,
    required String recordType,
    String? description,
    String? appointmentId,
    required List<PlatformFile> files,
  }) async {
    final form = FormData();
    form.fields.addAll([
      MapEntry('userId', userId),
      MapEntry('recordType', recordType),
      MapEntry('title', title),
      MapEntry('description', description ?? ''),
      MapEntry('docId', docId),
      MapEntry('doctorName', doctorName),
      MapEntry('date', DateTime.now().toIso8601String().split('T').first),
    ]);
    if (appointmentId != null) {
      form.fields.add(MapEntry('appointmentId', appointmentId));
    }
    for (final file in files) {
      if (file.bytes != null) {
        form.files.add(MapEntry(
          'files',
          MultipartFile.fromBytes(file.bytes!, filename: file.name),
        ));
      } else if (file.path != null) {
        form.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path!, filename: file.name),
        ));
      }
    }
    final res = await _api.dio.post<Map<String, dynamic>>(
      ApiConfig.healthRecords,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    assertSuccess(res.data ?? {}, 'Upload failed');
  }
}
