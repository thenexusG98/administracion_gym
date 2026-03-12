import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static Completer<Database>? _completer;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Evitar race condition: si ya se está inicializando, esperar
    if (_completer != null) {
      return _completer!.future;
    }

    _completer = Completer<Database>();
    try {
      debugPrint('🗄️ Inicializando base de datos...');
      _database = await _initDatabase();
      debugPrint('🗄️ ✅ Base de datos inicializada');
      _completer!.complete(_database!);
    } catch (e, st) {
      debugPrint('🗄️ ❌ Error inicializando DB: $e\n$st');
      _completer!.completeError(e, st);
      _completer = null;
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    debugPrint('🗄️ Obteniendo path de DB...');
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'valhalla_bjj.db');
    debugPrint('🗄️ Path: $path');

    debugPrint('🗄️ Abriendo DB...');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    debugPrint('🗄️ DB abierta, verificando tablas...');

    // Verificar que las tablas existen
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    final tableNames = tables.map((t) => t['name'] as String).toList();
    debugPrint('🗄️ Tablas encontradas: $tableNames');

    // Si faltan tablas, recrear
    if (!tableNames.contains('students') || !tableNames.contains('incomes')) {
      debugPrint('🗄️ ⚠️ Tablas faltantes, recreando...');
      await _onCreate(db, 1);
    }

    debugPrint('🗄️ DB lista');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🗄️ Creando tablas...');
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        fecha_inscripcion TEXT NOT NULL,
        tipo_plan TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha_proximo_pago TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'Activo',
        cinturon TEXT NOT NULL DEFAULT 'Blanco',
        notas TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha_pago TEXT NOT NULL,
        tipo_plan TEXT NOT NULL,
        concepto TEXT NOT NULL DEFAULT 'Mensualidad',
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS incomes (
        id TEXT PRIMARY KEY,
        categoria TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        reference_id TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        categoria TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        es_recurrente INTEGER NOT NULL DEFAULT 0,
        dia_recurrente INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        talla TEXT NOT NULL,
        precio_compra REAL NOT NULL,
        precio_venta REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        descripcion TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        cliente_nombre TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS monthly_goals (
        id TEXT PRIMARY KEY,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        meta_ingresos REAL NOT NULL,
        meta_alumnos REAL NOT NULL,
        notas TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(year, month)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Índices
    batch.execute('CREATE INDEX IF NOT EXISTS idx_students_estado ON students(estado)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_payments_student ON payments(student_id)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_payments_fecha ON payments(fecha_pago)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_incomes_fecha ON incomes(fecha)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_incomes_categoria ON incomes(categoria)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_expenses_fecha ON expenses(fecha)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_expenses_categoria ON expenses(categoria)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_products_categoria ON products(categoria)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_sales_fecha ON sales(fecha)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_sales_product ON sales(product_id)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(student_id)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_attendance_fecha ON attendance(fecha)');

    debugPrint('🗄️ Ejecutando batch de creación...');
    await batch.commit(noResult: true);
    debugPrint('🗄️ ✅ Tablas creadas OK');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations here
  }

  // ═══════════════════════════════════════════
  // GENERIC CRUD
  // ═══════════════════════════════════════════

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAll(String table, {String? orderBy}) async {
    final db = await database;
    return await db.query(table, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    final db = await database;
    return await db.query(table, where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markSynced(String table, String id) async {
    final db = await database;
    await db.update(table, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllSynced(String table) async {
    final db = await database;
    await db.update(table, {'synced': 1});
  }
}
