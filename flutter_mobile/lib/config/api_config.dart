import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// FastAPI backend endpoints (aligned with fastapi_back/ and mobile/ services).
class ApiConfig {
  ApiConfig._();

  static const String _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _dartDefineWebBaseUrl = String.fromEnvironment('API_BASE_URL_WEB');

  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  /// Same server as React Native `mobile/.env` → `EXPO_PUBLIC_API_URL`.
  /// Priority: --dart-define > bundled config.env > platform default.
  static String get baseUrl {
    if (_dartDefineBaseUrl.isNotEmpty) return _dartDefineBaseUrl;

    if (kIsWeb) {
      if (_dartDefineWebBaseUrl.isNotEmpty) return _dartDefineWebBaseUrl;
      final webUrl = _env('API_BASE_URL_WEB')?.trim();
      if (kDebugMode) {
        if (webUrl != null && webUrl.isNotEmpty) return webUrl;
        return 'http://localhost:5000';
      }
      // Release web: ignore localhost template; prefer production API.
      if (webUrl != null &&
          webUrl.isNotEmpty &&
          !_isLocalDevUrl(webUrl)) {
        return webUrl;
      }
      final fromDotEnv =
          _env('API_BASE_URL')?.trim() ?? _env('EXPO_PUBLIC_API_URL')?.trim();
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
      return 'https://medclues.onrender.com';
    }

    final fromDotEnv = _env('API_BASE_URL')?.trim() ?? _env('EXPO_PUBLIC_API_URL')?.trim();
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static bool _isLocalDevUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('localhost') ||
        lower.contains('127.0.0.1') ||
        lower.contains('10.0.2.2');
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Integrations
  static String get agoraAppId =>
      _env('AGORA_APP_ID')?.trim() ?? const String.fromEnvironment('AGORA_APP_ID');
  static String get telegramBotToken =>
      _env('TELEGRAM_BOT_TOKEN')?.trim() ?? const String.fromEnvironment('TELEGRAM_BOT_TOKEN');
  static String get telegramBotUsername {
    final fromEnv = _env('TELEGRAM_BOT_USERNAME')?.trim().replaceFirst('@', '');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    const fromDefine = String.fromEnvironment('TELEGRAM_BOT_USERNAME');
    if (fromDefine.isNotEmpty) return fromDefine.replaceFirst('@', '');
    return 'medcluesBot';
  }

  // Auth / user
  static const String userLogin = '/api/user/login';
  static const String userSocialLogin = '/api/user/social-login';
  static const String userRegister = '/api/user/register';
  static const String userProfile = '/api/user/get-profile';
  static const String userPatchProfile = '/api/user/profile';
  static const String userOnboarding = '/api/user/onboarding';
  static const String userSendEmailVerification = '/api/user/email/send-verification';
  static const String userVerifyEmail = '/api/user/email/verify';
  static const String userSignupSendEmailOtp = '/api/user/email/signup/send-otp';
  static const String userSignupVerifyEmailOtp = '/api/user/email/signup/verify-otp';
  static const String userUpdateProfile = '/api/user/update-profile';
  static const String userContact = '/api/user/contact';
  static const String savedProfiles = '/api/user/saved-profiles';
  static const String saveProfile = '/api/user/save-profile';
  static String savedProfile(String id) => '/api/user/saved-profiles/$id';
  static const String userEmergencyContacts = '/api/user/emergency-contacts';
  static const String userEmergencyContactAdd = '/api/user/emergency-contacts/add';
  static const String userEmergencyContactUpdate = '/api/user/emergency-contacts/update';
  static const String userEmergencyContactDelete = '/api/user/emergency-contacts/delete';
  static const String emergencyLogEvent = '/api/emergency/log-event';
  static const String emergencySendAlert = '/api/emergency/send-alert';
  static const String userFcmToken = '/api/user/fcm-token';
  static const String userNotifications = '/api/user/notifications';
  static const String userNotificationsRead = '/api/user/notifications/read';
  static const String userNotificationsReadAll = '/api/user/notifications/read-all';
  static const String userTelegramLinkCode = '/api/user/telegram/link-code';
  static const String userTelegramStatus = '/api/user/telegram/status';
  static const String userTelegramUnlink = '/api/user/telegram/link';

  // Health records
  static const String healthRecords = '/api/user/health-records';
  static String healthRecordViewUrl(String recordId, {int fileIndex = 0}) =>
      '/api/user/health-records/$recordId/view-url?fileIndex=$fileIndex';
  static String healthRecordFile(String recordId, {int fileIndex = 0}) =>
      '/api/user/health-records/$recordId/file?fileIndex=$fileIndex';

  // Payments
  static const String paymentsHistory = '/api/payments/history';
  static const String paymentsCreateOrder = '/api/payments/create-order';
  static const String paymentsVerify = '/api/payments/verify';
  static const String paymentsConfirmOrder = '/api/payments/confirm-order';
  static const String paymentsFailed = '/api/payments/failed';
  static String paymentsStatus(String orderId) => '/api/payments/status/$orderId';
  static String paymentsCheckout(String token, {String? preferredUpi}) {
    final q = StringBuffer('/api/payments/checkout?token=${Uri.encodeQueryComponent(token)}');
    if (preferredUpi != null && preferredUpi.trim().isNotEmpty) {
      q.write('&preferred_upi=${Uri.encodeQueryComponent(preferredUpi.trim())}');
    }
    return q.toString();
  }
  static const String paymentsRazorpayKey = '/api/payments/razorpay-key';

  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String authResetPassword = '/api/auth/reset-password';
  static const String authRefresh = '/api/auth/refresh';
  static const String authLogout = '/api/auth/logout';

  static const String sendOtp = '/api/send-otp';
  static const String verifyOtp = '/api/verify-otp';

  // Doctors
  static const String doctorList = '/api/doctor/list';
  static String doctorById(String id) => '/api/doctor/$id';
  static const String publicDoctors = '/api/hospital-tieup/public/doctors';

  // Specialities
  static const String specialtiesPublic = '/api/specialty/public/all';

  // Appointments
  static const String userAppointments = '/api/user/appointments';
  static const String bookAppointment = '/api/user/book-appointment';
  static const String cancelAppointment = '/api/user/cancel-appointment';
  static const String bookingConstraints = '/api/user/booking-constraints';
  static String appointmentLifecycle(String appointmentId) =>
      '/api/user/appointments/$appointmentId/lifecycle';
  static String consultationSummary(String appointmentId) =>
      '/api/user/appointments/$appointmentId/consultation-summary';
  static String appointmentQueueLive(String appointmentId) =>
      '/api/user/appointments/$appointmentId/queue-live';
  static String followupVisit(String appointmentId) =>
      '/api/user/appointments/$appointmentId/followup-visit';
  static String graceReschedule(String appointmentId) =>
      '/api/user/appointments/$appointmentId/grace-reschedule';

  static String confirmTomorrowReschedule(String appointmentId) =>
      '/api/user/appointments/$appointmentId/confirm-tomorrow-reschedule';
  /// Signed public BK lookup. [sig] is required (HMAC from sign_booking_lookup).
  static String appointmentByBookingId(String bookingId, {required String sig}) {
    final trimmed = sig.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(sig, 'sig', 'HMAC signature is required for BK lookup');
    }
    return '/api/appointments/$bookingId?sig=${Uri.encodeQueryComponent(trimmed)}';
  }
  static String publicAppointmentSummary(String bookingId, String sig) =>
      '/api/public/appointment-summary/$bookingId?sig=${Uri.encodeQueryComponent(sig)}';
  static String callRequestForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/call/request';
  static String callStatusForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/call/status';
  static String callCancelForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/call/cancel';
  static String agoraTokenForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/agora-token';
  static String videoCallStatusForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/video-call-status';
  static String syncCallTimerForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/sync-call-timer';
  static String endVideoCallForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/end-video-call';
  static String chatForAppointment(String appointmentId) =>
      '/api/user/appointments/$appointmentId/chat';
  static const String consultationCreate = '/api/user/consultation/create';
  static const String userConsultations = '/api/user/consultations';
  static String doctorSlots(String doctorId) => '/api/ai/doctor-slots/$doctorId';
  static const String aiAssistantStatus = '/api/ai/assistant/status';
  static const String aiAssistantChat = '/api/ai/assistant/chat';
  static const String aiAssistantConfirm = '/api/ai/assistant/confirm';
  static const String aiAssistantFeedback = '/api/ai/assistant/feedback';
  static const String aiAssistantTools = '/api/ai/assistant/tools';
  static String doctorScheduleSlots(String doctorId, {String mode = 'offline'}) =>
      '/api/doctor/$doctorId/slots?mode=$mode';

  // Hospitals
  static const String hospitalList = '/api/hospital-tieup/list';
  static String hospitalDetails(String id) => '/api/hospital-tieup/details/$id';

  // Location (nearby hospitals — OpenStreetMap via backend)
  static String nearbyHospitals(double lat, double lon, {double radiusKm = 10}) =>
      '/api/location/nearby-hospitals?lat=$lat&lon=$lon&radius=$radiusKm';

  // Labs
  static const String labList = '/api/lab/list';
}
