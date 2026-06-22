import 'package:valhalla_bjj/core/models/product_layaway.dart';
import 'package:valhalla_bjj/core/models/abono_producto.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';

class LayawayRepository {
  final DatabaseHelper _db;

  LayawayRepository(this._db);

  // ═══════════════════════════════════════════
  // APARTADOS
  // ═══════════════════════════════════════════

  Future<List<ProductLayaway>> getAll() async {
    final maps = await _db.getAll('product_layaways', orderBy: 'created_at DESC');
    return maps.map((m) => ProductLayaway.fromMap(m)).toList();
  }

  Future<List<ProductLayaway>> getPending() async {
    final maps = await _db.query(
      'product_layaways',
      where: 'estado = ?',
      whereArgs: ['Pendiente'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => ProductLayaway.fromMap(m)).toList();
  }

  Future<List<ProductLayaway>> getPendingByProduct(String productId) async {
    final maps = await _db.query(
      'product_layaways',
      where: 'product_id = ? AND estado = ?',
      whereArgs: [productId, 'Pendiente'],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => ProductLayaway.fromMap(m)).toList();
  }

  Future<ProductLayaway?> getById(String id) async {
    final map = await _db.getById('product_layaways', id);
    return map != null ? ProductLayaway.fromMap(map) : null;
  }

  Future<void> saveLayaway(ProductLayaway layaway) async {
    await _db.insert('product_layaways', layaway.toMap());
  }

  Future<void> updateLayaway(ProductLayaway layaway) async {
    await _db.update('product_layaways', layaway.toMap(), layaway.id);
  }

  // ═══════════════════════════════════════════
  // ABONOS
  // ═══════════════════════════════════════════

  Future<void> saveAbono(AbonoProducto abono) async {
    await _db.insert('abonos_producto', abono.toMap());
  }

  Future<List<AbonoProducto>> getAbonosByLayaway(String layawayId) async {
    final maps = await _db.query(
      'abonos_producto',
      where: 'layaway_id = ?',
      whereArgs: [layawayId],
      orderBy: 'fecha ASC',
    );
    return maps.map((m) => AbonoProducto.fromMap(m)).toList();
  }
}
