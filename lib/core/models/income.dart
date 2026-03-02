import 'package:uuid/uuid.dart';

class Income {
  final String id;
  final String categoria;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final String? referenceId; // ID del pago o venta relacionada
  final DateTime createdAt;
  final bool synced;

  Income({
    String? id,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    this.referenceId,
    DateTime? createdAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Income copyWith({
    String? categoria,
    String? descripcion,
    double? monto,
    DateTime? fecha,
    String? referenceId,
    bool? synced,
  }) {
    return Income(
      id: id,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt,
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
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String,
      categoria: map['categoria'] as String,
      descripcion: map['descripcion'] as String,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      referenceId: map['reference_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
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
      referenceId ?? '',
      createdAt.toIso8601String(),
    ];
  }
}
