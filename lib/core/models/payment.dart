import 'package:uuid/uuid.dart';

class Payment {
  final String id;
  final String studentId;
  final String studentName;
  final double monto;
  final DateTime fechaPago;
  final String tipoPlan;
  final String concepto;
  final DateTime createdAt;
  final bool synced;

  Payment({
    String? id,
    required this.studentId,
    required this.studentName,
    required this.monto,
    required this.fechaPago,
    required this.tipoPlan,
    this.concepto = 'Mensualidad',
    DateTime? createdAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Payment copyWith({
    double? monto,
    DateTime? fechaPago,
    String? tipoPlan,
    String? concepto,
    bool? synced,
  }) {
    return Payment(
      id: id,
      studentId: studentId,
      studentName: studentName,
      monto: monto ?? this.monto,
      fechaPago: fechaPago ?? this.fechaPago,
      tipoPlan: tipoPlan ?? this.tipoPlan,
      concepto: concepto ?? this.concepto,
      createdAt: createdAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'monto': monto,
      'fecha_pago': fechaPago.toIso8601String(),
      'tipo_plan': tipoPlan,
      'concepto': concepto,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      monto: (map['monto'] as num).toDouble(),
      fechaPago: DateTime.parse(map['fecha_pago'] as String),
      tipoPlan: map['tipo_plan'] as String,
      concepto: map['concepto'] as String? ?? 'Mensualidad',
      createdAt: DateTime.parse(map['created_at'] as String),
      synced: (map['synced'] as int?) == 1,
    );
  }

  List<String> toSheetRow() {
    return [
      id,
      studentId,
      studentName,
      monto.toString(),
      fechaPago.toIso8601String(),
      tipoPlan,
      concepto,
      createdAt.toIso8601String(),
    ];
  }
}
