import 'package:intl/intl.dart';

final NumberFormat _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20b9',
  decimalDigits: 0,
);

/// Full Indian grouping, matching the web CRM's `inr()` helper: ₹4,82,500.
String inr(num amount) => _rupees.format(amount);

/// Short form for KPI tiles, where the full figure will not fit: ₹1.92 Cr.
String inrCompact(num amount) {
  final double value = amount.toDouble().abs();
  final String sign = amount < 0 ? '-' : '';

  if (value >= 10000000) {
    return '$sign\u20b9${(value / 10000000).toStringAsFixed(2)} Cr';
  }
  if (value >= 100000) {
    return '$sign\u20b9${(value / 100000).toStringAsFixed(2)} L';
  }
  if (value >= 1000) {
    return '$sign\u20b9${(value / 1000).toStringAsFixed(1)} K';
  }
  return inr(amount);
}
