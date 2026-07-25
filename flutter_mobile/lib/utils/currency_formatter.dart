import '../config/app_config.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(num amount) =>
      '${AppConfig.currencySymbol}${amount.toStringAsFixed(0)}';
}
