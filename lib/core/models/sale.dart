import 'package:uuid/uuid.dart';

class Sale {
  final String id;
  final String productId;
  final String productName;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final DateTime fecha;
  final String? clienteNombre;
  final DateTime createdAt;
  final bool synced;

  Sale({
    String? id,
    required this.productId,
    required this.productName,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.fecha,
    this.clienteNombre,
    DateTime? createdAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'fecha': fecha.toIso8601String(),
      'cliente_nombre': clienteNombre,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      clienteNombre: map['cliente_nombre'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      synced: (map['synced'] as int?) == 1,
    );
  }

  List<String> toSheetRow() {
    return [
      id,
      productId,
      productName,
      cantidad.toString(),
      precioUnitario.toString(),
      total.toString(),
      fecha.toIso8601String(),
      clienteNombre ?? '',
      createdAt.toIso8601String(),
    ];
  }
}
