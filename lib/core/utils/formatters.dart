import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Centralised formatting helpers for currency, dates and numbers.
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 2,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: AppConstants.currencyLocale,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 1,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy • HH:mm');
  static final DateFormat _time = DateFormat('HH:mm');

  static String money(num value) => _currency.format(value);

  static String compactMoney(num value) => _compact.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String time(DateTime value) => _time.format(value);

  static String percent(double fraction) =>
      '${(fraction * 100).clamp(0, 100).toStringAsFixed(0)}%';

  /// Human friendly relative description of how soon a date occurs.
  static String daysUntil(DateTime target) {
    final now = DateTime.now();
    final difference =
        DateTime(target.year, target.month, target.day).difference(
      DateTime(now.year, now.month, now.day),
    );
    final days = difference.inDays;
    if (days < 0) return 'Expired ${days.abs()}d ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires in $days days';
  }
}
