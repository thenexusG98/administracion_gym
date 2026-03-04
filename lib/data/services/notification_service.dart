import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:valhalla_bjj/core/models/student.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';
import 'package:valhalla_bjj/data/repositories/student_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ═══════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔔 Inicializando servicio de notificaciones...');

    // Inicializar timezone
    tz.initializeTimeZones();

    // Configuración Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración general
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permiso en Android 13+
    await _requestPermissions();

    _initialized = true;
    debugPrint('🔔 ✅ Servicio de notificaciones inicializado');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notificación tocada: ${response.payload}');
    // Aquí se podría navegar al detalle del alumno
  }

  // ═══════════════════════════════════════════
  // CANAL DE NOTIFICACIONES
  // ═══════════════════════════════════════════

  static const _paymentChannel = AndroidNotificationDetails(
    'valhalla_payments',
    'Pagos de Alumnos',
    channelDescription: 'Recordatorios de fechas de pago de alumnos',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFFD4AF37), // Gold
    enableLights: true,
    enableVibration: true,
    playSound: true,
  );

  static const _paymentNotificationDetails = NotificationDetails(
    android: _paymentChannel,
  );

  // ═══════════════════════════════════════════
  // PROGRAMAR NOTIFICACIONES DE PAGOS
  // ═══════════════════════════════════════════

  /// Escanea todos los alumnos activos y programa notificaciones
  /// para los que tengan pagos próximos a vencer.
  Future<void> schedulePaymentReminders() async {
    if (!_initialized) {
      debugPrint('🔔 ⚠️ Servicio no inicializado, no se programan notificaciones');
      return;
    }

    debugPrint('🔔 Programando recordatorios de pago...');

    // Cancelar notificaciones anteriores para reprogramar
    await _notifications.cancelAll();

    final db = DatabaseHelper();
    final studentRepo = StudentRepository(db);
    final activeStudents = await studentRepo.getActiveStudents();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int scheduled = 0;

    for (final student in activeStudents) {
      final payDate = DateTime(
        student.fechaProximoPago.year,
        student.fechaProximoPago.month,
        student.fechaProximoPago.day,
      );
      final daysUntil = payDate.difference(today).inDays;

      // Notificar: 3 días antes, 1 día antes, el mismo día, y si está vencido
      if (daysUntil == 3) {
        await _showPaymentReminder(
          student: student,
          id: student.id.hashCode,
          title: '📅 Pago próximo en 3 días',
          body: '${student.nombre} - ${student.tipoPlan}: \$${student.monto.toStringAsFixed(0)} vence el ${_formatDate(student.fechaProximoPago)}',
        );
        scheduled++;
      } else if (daysUntil == 1) {
        await _showPaymentReminder(
          student: student,
          id: student.id.hashCode + 1,
          title: '⚠️ Pago mañana',
          body: '${student.nombre} - ${student.tipoPlan}: \$${student.monto.toStringAsFixed(0)} vence MAÑANA',
        );
        scheduled++;
      } else if (daysUntil == 0) {
        await _showPaymentReminder(
          student: student,
          id: student.id.hashCode + 2,
          title: '🔴 ¡Pago HOY!',
          body: '${student.nombre} - ${student.tipoPlan}: \$${student.monto.toStringAsFixed(0)} vence HOY',
        );
        scheduled++;
      } else if (daysUntil < 0 && daysUntil >= -7) {
        // Vencido hace hasta 7 días
        await _showPaymentReminder(
          student: student,
          id: student.id.hashCode + 3,
          title: '🚨 Pago vencido',
          body: '${student.nombre} tiene ${-daysUntil} días de atraso - \$${student.monto.toStringAsFixed(0)}',
        );
        scheduled++;
      }

      // Programar notificación futura para 3 días antes si falta más de 3 días
      if (daysUntil > 3) {
        final reminderDate = payDate.subtract(const Duration(days: 3));
        final scheduledDateTime = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9, // 9:00 AM
          0,
        );

        // Solo programar si la fecha es en el futuro
        if (scheduledDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: student.id.hashCode + 10,
            title: '📅 Pago próximo en 3 días',
            body: '${student.nombre} - ${student.tipoPlan}: \$${student.monto.toStringAsFixed(0)} vence el ${_formatDate(student.fechaProximoPago)}',
            scheduledDate: scheduledDateTime,
            payload: student.id,
          );
          scheduled++;
        }
      }

      // Programar notificación para 1 día antes
      if (daysUntil > 1) {
        final reminderDate = payDate.subtract(const Duration(days: 1));
        final scheduledDateTime = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9, // 9:00 AM
          0,
        );

        if (scheduledDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: student.id.hashCode + 11,
            title: '⚠️ Pago mañana',
            body: '${student.nombre} - ${student.tipoPlan}: \$${student.monto.toStringAsFixed(0)} vence MAÑANA',
            scheduledDate: scheduledDateTime,
            payload: student.id,
          );
          scheduled++;
        }
      }

      // Programar notificación para el mismo día
      if (daysUntil > 0) {
        final scheduledDateTime = DateTime(
          payDate.year,
          payDate.month,
          payDate.day,
          8, // 8:00 AM
          0,
        );

        if (scheduledDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: student.id.hashCode + 12,
            title: '🔴 ¡Pago HOY!',
            body: '${student.nombre} - ${student.tipoPlan}: \$${student.monto.toStringAsFixed(0)} vence HOY',
            scheduledDate: scheduledDateTime,
            payload: student.id,
          );
          scheduled++;
        }
      }
    }

    debugPrint('🔔 ✅ $scheduled notificaciones programadas para ${activeStudents.length} alumnos activos');
  }

  // ═══════════════════════════════════════════
  // MOSTRAR NOTIFICACIÓN INMEDIATA
  // ═══════════════════════════════════════════

  Future<void> _showPaymentReminder({
    required Student student,
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _paymentNotificationDetails,
      payload: student.id,
    );
  }

  // ═══════════════════════════════════════════
  // PROGRAMAR NOTIFICACIÓN FUTURA
  // ═══════════════════════════════════════════

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _toTZDateTime(scheduledDate),
        _paymentNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: payload,
      );
      debugPrint('🔔 Programada: "$title" para $scheduledDate');
    } catch (e) {
      debugPrint('🔔 ❌ Error programando notificación: $e');
      // Si falla la programación, no es crítico
    }
  }

  // ═══════════════════════════════════════════
  // NOTIFICACIÓN MANUAL / TEST
  // ═══════════════════════════════════════════

  /// Muestra una notificación de prueba
  Future<void> showTestNotification() async {
    await _notifications.show(
      0,
      '🔔 Valhalla BJJ',
      'Las notificaciones están funcionando correctamente',
      _paymentNotificationDetails,
    );
  }

  /// Notificación cuando se registra un pago exitoso
  Future<void> showPaymentConfirmation(String studentName, double amount) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✅ Pago registrado',
      '$studentName - \$${amount.toStringAsFixed(0)}',
      _paymentNotificationDetails,
    );
  }

  // ═══════════════════════════════════════════
  // CANCELAR
  // ═══════════════════════════════════════════

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('🔔 Todas las notificaciones canceladas');
  }

  Future<void> cancelForStudent(String studentId) async {
    final baseId = studentId.hashCode;
    for (int i = 0; i <= 12; i++) {
      await _notifications.cancel(baseId + i);
    }
    debugPrint('🔔 Notificaciones canceladas para alumno $studentId');
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════

  /// Convierte DateTime a TZDateTime (usando offset local)
  tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Obtener cantidad de notificaciones pendientes
  Future<int> getPendingCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
}
