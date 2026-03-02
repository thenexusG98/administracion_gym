import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final String categoria;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final bool esRecurrente;
  final int? diaRecurrente; // Día del mes para gastos recurrentes
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Expense({
    String? id,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    this.esRecurrente = false,
    this.diaRecurrente,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Expense copyWith({
    String? categoria,
    String? descripcion,
    double? monto,
    DateTime? fecha,
    bool? esRecurrente,
    int? diaRecurrente,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Expense(
      id: id,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      diaRecurrente: diaRecurrente ?? this.diaRecurrente,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'es_recurrente': esRecurrente ? 1 : 0,
      'dia_recurrente': diaRecurrente,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      categoria: map['categoria'] as String,
      descripcion: map['descripcion'] as String,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      esRecurrente: (map['es_recurrente'] as int?) == 1,
      diaRecurrente: map['dia_recurrente'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      synced: (map['synced'] as int?) == 1,
    );
  }

  List<String> toSheetRow() {
    return [
      id,
      categoria,
      descripcion,
      monto.toString(),
      fecha.toIso8601String(),
      esRecurrente.toString(),
      (diaRecurrente ?? '').toString(),
      createdAt.toIso8601String(),
    ];
  }
}
