class AppConfig {

  AppConfig._();



  static const String appName = 'MEDCLUES';

  static const String appTagline = 'EMERGENCY | BOOKING';

  static const String brandSubtitle = 'SINCE 2026';

  /// Support inbox shown in Contact Us / Help (override with --dart-define=SUPPORT_EMAIL=...).
  /// Testing default until support@medclues.com is provisioned.
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'medichain123@gmail.com',
  );

  static const String supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '1800-123-4567',
  );

  static const int splashDurationMs = 2500;

  /// Opening intro video — replace `assets/videos/opening.mp4` (same name) to change splash video.
  /// Banner illustration: replace `assets/images/banner_navigation.png`.
  static const String splashVideoAsset = 'assets/videos/opening.mp4';

  static const String currency = 'INR';

  static const String currencySymbol = '₹';

  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;

}

