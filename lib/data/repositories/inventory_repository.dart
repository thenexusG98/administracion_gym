import 'package:valhalla_bjj/core/models/product.dart';
import 'package:valhalla_bjj/core/models/sale.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';

class InventoryRepository {
  final DatabaseHelper _db;

  InventoryRepository(this._db);

  // ═══════════════════════════════════════════
  // PRODUCTOS
  // ═══════════════════════════════════════════

  Future<List<Product>> getAllProducts() async {
    final maps = await _db.getAll('products', orderBy: 'nombre ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final map = await _db.getById('products', id);
    return map != null ? Product.fromMap(map) : null;
  }

  Future<List<Product>> getProductsByCategoria(String categoria) async {
    final maps = await _db.query(
      'products',
      where: 'categoria = ?',
      whereArgs: [categoria],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final maps = await _db.query(
      'products',
      where: 'stock <= ?',
      whereArgs: [3],
      orderBy: 'stock ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> saveProduct(Product product) async {
    await _db.insert('products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db.update('products', product.copyWith(synced: false).toMap(), product.id);
  }

  Future<void> deleteProduct(String id) async {
    await _db.delete('products', id);
  }

  Future<void> decrementStock(String productId, int quantity) async {
    final product = await getProductById(productId);
    if (product != null && product.stock >= quantity) {
      await updateProduct(product.copyWith(stock: product.stock - quantity));
    }
  }

  // ═══════════════════════════════════════════
  // VENTAS
  // ═══════════════════════════════════════════

  Future<List<Sale>> getAllSales() async {
    final maps = await _db.getAll('sales', orderBy: 'fecha DESC');
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'sales',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<double> getSalesTotalByDateRange(DateTime start, DateTime end) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) as total FROM sales WHERE fecha >= ? AND fecha <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, int>> getTopSellingProducts({int limit = 5}) async {
    final result = await _db.rawQuery(
      '''SELECT product_name, SUM(cantidad) as total_vendido 
         FROM sales 
         GROUP BY product_id, product_name 
         ORDER BY total_vendido DESC 
         LIMIT ?''',
      [limit],
    );
    final map = <String, int>{};
    for (final row in result) {
      map[row['product_name'] as String] = (row['total_vendido'] as num).toInt();
    }
    return map;
  }

  Future<void> saveSale(Sale sale) async {
    await _db.insert('sales', sale.toMap());
  }

  Future<List<Product>> getUnsyncedProducts() async {
    final maps = await _db.getUnsynced('products');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Sale>> getUnsyncedSales() async {
    final maps = await _db.getUnsynced('sales');
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<void> markProductSynced(String id) async {
    await _db.markSynced('products', id);
  }

  Future<void> markSaleSynced(String id) async {
    await _db.markSynced('sales', id);
  }
}
