import 'package:valhalla_bjj/core/models/payment.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';

class PaymentRepository {
  final DatabaseHelper _db;

  PaymentRepository(this._db);

  Future<List<Payment>> getAll() async {
    final maps = await _db.getAll('payments', orderBy: 'fecha_pago DESC');
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getByStudent(String studentId) async {
    final maps = await _db.query(
      'payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'fecha_pago DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getByDateRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'payments',
      where: 'fecha_pago >= ? AND fecha_pago <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'fecha_pago DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM payments WHERE fecha_pago >= ? AND fecha_pago <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<void> save(Payment payment) async {
    await _db.insert('payments', payment.toMap());
  }

  Future<void> delete(String id) async {
    await _db.delete('payments', id);
  }

  Future<List<Payment>> getUnsynced() async {
    final maps = await _db.getUnsynced('payments');
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    await _db.markSynced('payments', id);
  }
}
