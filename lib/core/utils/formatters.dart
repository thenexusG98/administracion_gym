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
  static final _shortDateFormat = DateFormat('dd MMM');

  static String currency(double amount) {
    try {
      return _currencyFormat.format(amount);
    } catch (_) {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String monthYear(DateTime date) {
    try {
      final format = DateFormat('MMMM yyyy', 'es');
      final formatted = format.format(date);
      return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
    } catch (_) {
      // Fallback si el locale no está inicializado
      const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
  }

  static String shortDate(DateTime date) {
    try {
      return _shortDateFormat.format(date);
    } catch (_) {
      return '${date.day}/${date.month}';
    }
  }

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
