import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(num? amount, {bool showDecimals = true}) {
    if (amount == null) return '₹0.00';
    return showDecimals ? _inrFormat.format(amount) : _inrNoDecimals.format(amount);
  }

  static String formatApprox(num? amount) {
    if (amount == null) return '~₹0.00';
    return '~${_inrFormat.format(amount)}';
  }
}
