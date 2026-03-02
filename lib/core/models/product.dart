import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String nombre;
  final String categoria;
  final String talla;
  final double precioCompra;
  final double precioVenta;
  final int stock;
  final String? descripcion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Product({
    String? id,
    required this.nombre,
    required this.categoria,
    required this.talla,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    this.descripcion,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Product copyWith({
    String? nombre,
    String? categoria,
    String? talla,
    double? precioCompra,
    double? precioVenta,
    int? stock,
    String? descripcion,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Product(
      id: id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      talla: talla ?? this.talla,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stock: stock ?? this.stock,
      descripcion: descripcion ?? this.descripcion,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      synced: synced ?? this.synced,
    );
  }

  double get ganancia => precioVenta - precioCompra;
  double get margenGanancia => precioCompra > 0 ? (ganancia / precioCompra) * 100 : 0;
  bool get stockBajo => stock <= 3;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'talla': talla,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'stock': stock,
      'descripcion': descripcion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String,
      talla: map['talla'] as String,
      precioCompra: (map['precio_compra'] as num).toDouble(),
      precioVenta: (map['precio_venta'] as num).toDouble(),
      stock: map['stock'] as int,
      descripcion: map['descripcion'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      synced: (map['synced'] as int?) == 1,
    );
  }

  List<String> toSheetRow() {
    return [
      id,
      nombre,
      categoria,
      talla,
      precioCompra.toString(),
      precioVenta.toString(),
      stock.toString(),
      descripcion ?? '',
      createdAt.toIso8601String(),
      updatedAt.toIso8601String(),
    ];
  }
}
