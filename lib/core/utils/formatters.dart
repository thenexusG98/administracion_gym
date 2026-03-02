import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'es');
  static final _shortDateFormat = DateFormat('dd MMM', 'es');

  static String currency(double amount) => _currencyFormat.format(amount);

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String monthYear(DateTime date) {
    final formatted = _monthYearFormat.format(date);
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  static String daysRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final diff = targetDate.difference(now).inDays;
    if (diff < 0) return 'Vencido hace ${-diff} días';
    if (diff == 0) return 'Vence hoy';
    if (diff == 1) return 'Vence mañana';
    return 'Vence en $diff días';
  }

  static String percentage(double value) => '${value.toStringAsFixed(1)}%';
}
