import 'package:uuid/uuid.dart';

/// Representa un apartado/anticipo sobre un producto del inventario.
/// El cliente deja un depósito inicial y puede abonar hasta liquidar el total.
class ProductLayaway {
  final String id;
  final String productId;
  final String productName;
  final String clienteNombre;
  final String? clienteTelefono;
  final int cantidad;
  final double precioUnitario;
  final double precioTotal;
  final double montoAbonado;
  final String estado; // 'Pendiente', 'Completado', 'Cancelado'
  final DateTime fecha;
  final String? notas;
  final DateTime createdAt;
  final bool synced;

  ProductLayaway({
    String? id,
    required this.productId,
    required this.productName,
    required this.clienteNombre,
    this.clienteTelefono,
    required this.cantidad,
    required this.precioUnitario,
    required this.precioTotal,
    required this.montoAbonado,
    this.estado = 'Pendiente',
    required this.fecha,
    this.notas,
    DateTime? createdAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get saldo => precioTotal - montoAbonado;
  double get porcentajePagado =>
      precioTotal > 0 ? (montoAbonado / precioTotal).clamp(0.0, 1.0) : 0.0;
  bool get completado => estado == 'Completado';
  bool get pendiente => estado == 'Pendiente';
  bool get cancelado => estado == 'Cancelado';

  ProductLayaway copyWith({
    double? montoAbonado,
    String? estado,
    bool? synced,
  }) {
    return ProductLayaway(
      id: id,
      productId: productId,
      productName: productName,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      precioTotal: precioTotal,
      montoAbonado: montoAbonado ?? this.montoAbonado,
      estado: estado ?? this.estado,
      fecha: fecha,
      notas: notas,
      createdAt: createdAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'precio_total': precioTotal,
      'monto_abonado': montoAbonado,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory ProductLayaway.fromMap(Map<String, dynamic> map) {
    return ProductLayaway(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      clienteNombre: map['cliente_nombre'] as String,
      clienteTelefono: map['cliente_telefono'] as String?,
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      precioTotal: (map['precio_total'] as num).toDouble(),
      montoAbonado: (map['monto_abonado'] as num).toDouble(),
      estado: map['estado'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      notas: map['notas'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      synced: (map['synced'] as int?) == 1,
    );
  }
}
