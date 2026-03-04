import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/models/student.dart';
import 'package:valhalla_bjj/core/models/payment.dart';
import 'package:valhalla_bjj/providers/providers.dart';

// ═══════════════════════════════════════════
// LISTA DE ALUMNOS
// ═══════════════════════════════════════════
final studentsProvider = StateNotifierProvider<StudentsNotifier, AsyncValue<List<Student>>>((ref) {
  return StudentsNotifier(ref);
});

class StudentsNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final Ref _ref;

  StudentsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final students = await _ref.read(studentRepositoryProvider).getAll();
      state = AsyncValue.data(students);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addStudent(Student student) async {
    try {
      await _ref.read(studentRepositoryProvider).save(student);
      await loadStudents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      await _ref.read(studentRepositoryProvider).update(student);
      await loadStudents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _ref.read(studentRepositoryProvider).delete(id);
      await loadStudents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<Student>> search(String query) async {
    return _ref.read(studentRepositoryProvider).search(query);
  }
}

// ═══════════════════════════════════════════
// ALUMNOS ACTIVOS COUNT
// ═══════════════════════════════════════════
final activeStudentsCountProvider = FutureProvider<int>((ref) async {
  return ref.read(studentRepositoryProvider).getActiveCount();
});

// ═══════════════════════════════════════════
// ALUMNOS POR VENCER
// ═══════════════════════════════════════════
final expiringSoonStudentsProvider = FutureProvider<List<Student>>((ref) async {
  return ref.read(studentRepositoryProvider).getExpiringSoon();
});

// ═══════════════════════════════════════════
// PAGOS POR ALUMNO
// ═══════════════════════════════════════════
final studentPaymentsProvider = FutureProvider.family<List<Payment>, String>((ref, studentId) async {
  return ref.read(paymentRepositoryProvider).getByStudent(studentId);
});
