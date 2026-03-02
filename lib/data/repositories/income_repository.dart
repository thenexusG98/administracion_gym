import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';

class IncomeRepository {
  final DatabaseHelper _db;

  IncomeRepository(this._db);

  Future<List<Income>> getAll() async {
    final maps = await _db.getAll('incomes', orderBy: 'fecha DESC');
    return maps.map((m) => Income.fromMap(m)).toList();
  }

  Future<Income?> getById(String id) async {
    final map = await _db.getById('incomes', id);
    return map != null ? Income.fromMap(map) : null;
  }

  Future<List<Income>> getByDateRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'incomes',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Income.fromMap(m)).toList();
  }

  Future<List<Income>> getByCategoria(String categoria) async {
    final maps = await _db.query(
      'incomes',
      where: 'categoria = ?',
      whereArgs: [categoria],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Income.fromMap(m)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM incomes WHERE fecha >= ? AND fecha <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getDailyTotal(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return getTotalByDateRange(start, end);
  }

  Future<Map<String, double>> getTotalsByCategoria(DateTime start, DateTime end) async {
    final result = await _db.rawQuery(
      'SELECT categoria, COALESCE(SUM(monto), 0) as total FROM incomes WHERE fecha >= ? AND fecha <= ? GROUP BY categoria',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final map = <String, double>{};
    for (final row in result) {
      map[row['categoria'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  Future<void> save(Income income) async {
    await _db.insert('incomes', income.toMap());
  }

  Future<void> update(Income income) async {
    await _db.update('incomes', income.copyWith(synced: false).toMap(), income.id);
  }

  Future<void> delete(String id) async {
    await _db.delete('incomes', id);
  }

  Future<List<Income>> getUnsynced() async {
    final maps = await _db.getUnsynced('incomes');
    return maps.map((m) => Income.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    await _db.markSynced('incomes', id);
  }
}
