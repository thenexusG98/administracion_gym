import 'package:uuid/uuid.dart';

/// Representa un pago/abono individual sobre un apartado de producto.
class AbonoProducto {
  final String id;
  final String layawayId;
  final double monto;
  final DateTime fecha;
  final String? notas;
  final DateTime createdAt;

  AbonoProducto({
    String? id,
    required this.layawayId,
    required this.monto,
    required this.fecha,
    this.notas,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'layaway_id': layawayId,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AbonoProducto.fromMap(Map<String, dynamic> map) {
    return AbonoProducto(
      id: map['id'] as String,
      layawayId: map['layaway_id'] as String,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      notas: map['notas'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
