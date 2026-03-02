import 'package:valhalla_bjj/core/models/expense.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';

class ExpenseRepository {
  final DatabaseHelper _db;

  ExpenseRepository(this._db);

  Future<List<Expense>> getAll() async {
    final maps = await _db.getAll('expenses', orderBy: 'fecha DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<Expense?> getById(String id) async {
    final map = await _db.getById('expenses', id);
    return map != null ? Expense.fromMap(map) : null;
  }

  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'expenses',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getByCategoria(String categoria) async {
    final maps = await _db.query(
      'expenses',
      where: 'categoria = ?',
      whereArgs: [categoria],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getRecurrentes() async {
    final maps = await _db.query(
      'expenses',
      where: 'es_recurrente = ?',
      whereArgs: [1],
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM expenses WHERE fecha >= ? AND fecha <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getTotalsByCategoria(DateTime start, DateTime end) async {
    final result = await _db.rawQuery(
      'SELECT categoria, COALESCE(SUM(monto), 0) as total FROM expenses WHERE fecha >= ? AND fecha <= ? GROUP BY categoria',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final map = <String, double>{};
    for (final row in result) {
      map[row['categoria'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  Future<void> save(Expense expense) async {
    await _db.insert('expenses', expense.toMap());
  }

  Future<void> update(Expense expense) async {
    await _db.update('expenses', expense.copyWith(synced: false).toMap(), expense.id);
  }

  Future<void> delete(String id) async {
    await _db.delete('expenses', id);
  }

  Future<List<Expense>> getUnsynced() async {
    final maps = await _db.getUnsynced('expenses');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    await _db.markSynced('expenses', id);
  }
}
