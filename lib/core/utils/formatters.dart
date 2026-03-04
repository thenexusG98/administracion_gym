import 'package:intl/intl.dart';
import 'package:valhalla_bjj/core/models/student.dart';

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
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return 'Vencido hace ${-diff} días';
    if (diff == 0) return 'Vence hoy';
    if (diff == 1) return 'Vence mañana';
    return 'Vence en $diff días';
  }

  /// Devuelve el estado de pago legible para un alumno
  static String paymentStatus(Student student) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      student.fechaProximoPago.year,
      student.fechaProximoPago.month,
      student.fechaProximoPago.day,
    );
    final diff = target.difference(today).inDays;

    if (student.tipoPlan == 'Clase suelta') {
      // Para clase suelta: si la fecha es hoy o futura, está al corriente
      if (diff >= 0) return '✅ Pagado';
      return '⚠️ Sin pago reciente';
    }

    // Para planes recurrentes (Mensual, Quincenal)
    if (diff < 0) return '🔴 Vencido hace ${-diff} días';
    if (diff == 0) return '⚠️ Vence hoy';
    if (diff <= 3) return '⚠️ Vence en $diff días';
    return '✅ Al corriente (vence en $diff días)';
  }

  static String percentage(double value) => '${value.toStringAsFixed(1)}%';

  /// Genera el concepto descriptivo del pago según el tipo de plan
  static String paymentConcept(String tipoPlan, DateTime fechaPago) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    String _short(DateTime d) {
      final dia = d.day.toString().padLeft(2, '0');
      final mes = months[d.month - 1].substring(0, 3);
      return '$dia $mes';
    }

    switch (tipoPlan) {
      case 'Mensual':
        final mes = months[fechaPago.month - 1];
        return 'Mensualidad - $mes ${fechaPago.year}';
      case 'Quincenal':
        final fin = fechaPago.add(const Duration(days: 15));
        return 'Quincena - ${_short(fechaPago)} al ${_short(fin)} ${fin.year}';
      case 'Clase suelta':
        final dia = fechaPago.day.toString().padLeft(2, '0');
        final mesCorto = months[fechaPago.month - 1].substring(0, 3);
        return 'Clase suelta - $dia $mesCorto ${fechaPago.year}';
      default:
        final mes = months[fechaPago.month - 1];
        return 'Pago - $mes ${fechaPago.year}';
    }
  }
}
