import 'package:uuid/uuid.dart';

class Student {
  final String id;
  final String nombre;
  final String telefono;
  final DateTime fechaInscripcion;
  final String tipoPlan;
  final double monto;
  final DateTime fechaProximoPago;
  final String estado;
  final String cinturon;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Student({
    String? id,
    required this.nombre,
    required this.telefono,
    required this.fechaInscripcion,
    required this.tipoPlan,
    required this.monto,
    required this.fechaProximoPago,
    this.estado = 'Activo',
    this.cinturon = 'Blanco',
    this.notas,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Student copyWith({
    String? nombre,
    String? telefono,
    DateTime? fechaInscripcion,
    String? tipoPlan,
    double? monto,
    DateTime? fechaProximoPago,
    String? estado,
    String? cinturon,
    String? notas,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Student(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      fechaInscripcion: fechaInscripcion ?? this.fechaInscripcion,
      tipoPlan: tipoPlan ?? this.tipoPlan,
      monto: monto ?? this.monto,
      fechaProximoPago: fechaProximoPago ?? this.fechaProximoPago,
      estado: estado ?? this.estado,
      cinturon: cinturon ?? this.cinturon,
      notas: notas ?? this.notas,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'fecha_inscripcion': fechaInscripcion.toIso8601String(),
      'tipo_plan': tipoPlan,
      'monto': monto,
      'fecha_proximo_pago': fechaProximoPago.toIso8601String(),
      'estado': estado,
      'cinturon': cinturon,
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String,
      fechaInscripcion: DateTime.parse(map['fecha_inscripcion'] as String),
      tipoPlan: map['tipo_plan'] as String,
      monto: (map['monto'] as num).toDouble(),
      fechaProximoPago: DateTime.parse(map['fecha_proximo_pago'] as String),
      estado: map['estado'] as String? ?? 'Activo',
      cinturon: map['cinturon'] as String? ?? 'Blanco',
      notas: map['notas'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      synced: (map['synced'] as int?) == 1,
    );
  }

  List<String> toSheetRow() {
    return [
      id,
      nombre,
      telefono,
      fechaInscripcion.toIso8601String(),
      tipoPlan,
      monto.toString(),
      fechaProximoPago.toIso8601String(),
      estado,
      cinturon,
      notas ?? '',
      createdAt.toIso8601String(),
      updatedAt.toIso8601String(),
    ];
  }

  bool get isExpiringSoon {
    final daysUntilExpiry = fechaProximoPago.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0 && estado == 'Activo';
  }

  bool get isExpired {
    return fechaProximoPago.isBefore(DateTime.now()) && estado == 'Activo';
  }
}
