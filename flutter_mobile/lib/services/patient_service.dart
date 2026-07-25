import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/patient_model.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class PatientService {
  PatientService(this._api);

  final ApiService _api;

  Future<PatientModel> getProfile() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConfig.userProfile);
    final data = res.data ?? {};
    assertSuccess(data);
    final user = (data['userData'] ?? data['user']) as Map<String, dynamic>?;
    if (user == null) throw Exception('Profile unavailable');
    return PatientModel.fromJson(user);
  }

  Future<PatientModel> updateProfile(PatientModel patient) async {
    final res = await _api.patch<Map<String, dynamic>>(
      ApiConfig.userPatchProfile,
      data: patient.toPatchJson(),
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Update failed');
    final user = (data['userData'] ?? data['user']) as Map<String, dynamic>?;
    return user != null ? PatientModel.fromJson(user) : patient;
  }

  Future<PatientModel> updateAddress({required String line1, required String line2}) async {
    final res = await _api.patch<Map<String, dynamic>>(
      ApiConfig.userPatchProfile,
      data: {
        'address': {'line1': line1.trim(), 'line2': line2.trim()},
      },
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Update failed');
    final user = (data['userData'] ?? data['user']) as Map<String, dynamic>?;
    if (user == null) throw Exception('Address update failed');
    return PatientModel.fromJson(user);
  }

  Future<String?> uploadPhoto(XFile file) async {
    final MultipartFile imagePart;
    if (kIsWeb) {
      imagePart = MultipartFile.fromBytes(
        await file.readAsBytes(),
        filename: 'profile_photo.jpg',
      );
    } else {
      final path = file.path;
      if (path.isEmpty) throw Exception('Invalid image file');
      imagePart = await MultipartFile.fromFile(path, filename: 'profile_photo.jpg');
    }
    final form = FormData.fromMap({'image': imagePart});
    final res = await _api.dio.post<Map<String, dynamic>>(
      ApiConfig.userUpdateProfile,
      data: form,
      options: Options(contentType: 'multipart/form-data', sendTimeout: const Duration(seconds: 30)),
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Upload failed');
    return data['profile_pic_url']?.toString() ??
        (data['userData'] as Map?)?['image']?.toString();
  }

  /// Public Contact Us form → backend emails SUPPORT_EMAIL.
  Future<void> sendContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.userContact,
      data: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      },
    );
    assertSuccess(res.data ?? {}, 'Could not send your message');
  }
}
