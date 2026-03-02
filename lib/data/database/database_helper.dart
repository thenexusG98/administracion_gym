import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'valhalla_bjj.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
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

    await db.execute('''
      CREATE TABLE payments (
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

    await db.execute('''
      CREATE TABLE incomes (
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

    await db.execute('''
      CREATE TABLE expenses (
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

    await db.execute('''
      CREATE TABLE products (
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

    await db.execute('''
      CREATE TABLE sales (
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

    await db.execute('''
      CREATE TABLE monthly_goals (
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

    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Índices para búsquedas rápidas
    await db.execute('CREATE INDEX idx_students_estado ON students(estado)');
    await db.execute('CREATE INDEX idx_payments_student ON payments(student_id)');
    await db.execute('CREATE INDEX idx_payments_fecha ON payments(fecha_pago)');
    await db.execute('CREATE INDEX idx_incomes_fecha ON incomes(fecha)');
    await db.execute('CREATE INDEX idx_incomes_categoria ON incomes(categoria)');
    await db.execute('CREATE INDEX idx_expenses_fecha ON expenses(fecha)');
    await db.execute('CREATE INDEX idx_expenses_categoria ON expenses(categoria)');
    await db.execute('CREATE INDEX idx_products_categoria ON products(categoria)');
    await db.execute('CREATE INDEX idx_sales_fecha ON sales(fecha)');
    await db.execute('CREATE INDEX idx_sales_product ON sales(product_id)');
    await db.execute('CREATE INDEX idx_attendance_student ON attendance(student_id)');
    await db.execute('CREATE INDEX idx_attendance_fecha ON attendance(fecha)');
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
