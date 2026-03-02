import 'package:valhalla_bjj/core/models/student.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';

class StudentRepository {
  final DatabaseHelper _db;

  StudentRepository(this._db);

  Future<List<Student>> getAll() async {
    final maps = await _db.getAll('students', orderBy: 'nombre ASC');
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<Student?> getById(String id) async {
    final map = await _db.getById('students', id);
    return map != null ? Student.fromMap(map) : null;
  }

  Future<List<Student>> getByEstado(String estado) async {
    final maps = await _db.query(
      'students',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<List<Student>> getActiveStudents() async {
    return getByEstado('Activo');
  }

  Future<List<Student>> getExpiringSoon() async {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 3));
    final maps = await _db.query(
      'students',
      where: 'estado = ? AND fecha_proximo_pago <= ? AND fecha_proximo_pago >= ?',
      whereArgs: ['Activo', threshold.toIso8601String(), now.toIso8601String()],
      orderBy: 'fecha_proximo_pago ASC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<List<Student>> getExpired() async {
    final now = DateTime.now();
    final maps = await _db.query(
      'students',
      where: 'estado = ? AND fecha_proximo_pago < ?',
      whereArgs: ['Activo', now.toIso8601String()],
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<int> getActiveCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE estado = ?',
      ['Activo'],
    );
    return result.first['count'] as int;
  }

  Future<void> save(Student student) async {
    await _db.insert('students', student.toMap());
  }

  Future<void> update(Student student) async {
    await _db.update('students', student.copyWith(synced: false).toMap(), student.id);
  }

  Future<void> delete(String id) async {
    await _db.delete('students', id);
  }

  Future<List<Student>> search(String query) async {
    final maps = await _db.query(
      'students',
      where: 'nombre LIKE ? OR telefono LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<List<Student>> getUnsynced() async {
    final maps = await _db.getUnsynced('students');
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    await _db.markSynced('students', id);
  }
}
