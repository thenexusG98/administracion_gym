class MonthlyGoal {
  final String id;
  final int year;
  final int month;
  final double metaIngresos;
  final double metaAlumnos;
  final String? notas;
  final DateTime createdAt;

  MonthlyGoal({
    required this.id,
    required this.year,
    required this.month,
    required this.metaIngresos,
    required this.metaAlumnos,
    this.notas,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'meta_ingresos': metaIngresos,
      'meta_alumnos': metaAlumnos,
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MonthlyGoal.fromMap(Map<String, dynamic> map) {
    return MonthlyGoal(
      id: map['id'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      metaIngresos: (map['meta_ingresos'] as num).toDouble(),
      metaAlumnos: (map['meta_alumnos'] as num).toDouble(),
      notas: map['notas'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class Attendance {
  final String id;
  final String studentId;
  final String studentName;
  final DateTime fecha;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.fecha,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'fecha': fecha.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
