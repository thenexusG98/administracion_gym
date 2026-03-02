import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valhalla_bjj/core/constants/app_constants.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';
import 'package:valhalla_bjj/data/repositories/student_repository.dart';
import 'package:valhalla_bjj/data/repositories/payment_repository.dart';
import 'package:valhalla_bjj/data/repositories/income_repository.dart';
import 'package:valhalla_bjj/data/repositories/expense_repository.dart';
import 'package:valhalla_bjj/data/repositories/inventory_repository.dart';

class GoogleSheetsService {
  static const _spreadsheetIdKey = 'spreadsheet_id';

  final GoogleSignIn _googleSignIn;
  final DatabaseHelper _db;

  sheets.SheetsApi? _sheetsApi;
  String? _spreadsheetId;
  bool _isInitialized = false;

  GoogleSheetsService({
    GoogleSignIn? googleSignIn,
    DatabaseHelper? db,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'https://www.googleapis.com/auth/spreadsheets',
                'https://www.googleapis.com/auth/drive.file',
              ],
            ),
        _db = db ?? DatabaseHelper();

  bool get isInitialized => _isInitialized;
  String? get spreadsheetId => _spreadsheetId;

  // ═══════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════

  Future<bool> initialize() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      _sheetsApi = sheets.SheetsApi(client);

      // Cargar ID del spreadsheet guardado
      final prefs = await SharedPreferences.getInstance();
      _spreadsheetId = prefs.getString(_spreadsheetIdKey);

      if (_spreadsheetId == null) {
        await _createSpreadsheet();
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      _sheetsApi = sheets.SheetsApi(client);

      final prefs = await SharedPreferences.getInstance();
      _spreadsheetId = prefs.getString(_spreadsheetIdKey);

      if (_spreadsheetId == null) {
        await _createSpreadsheet();
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _sheetsApi = null;
    _isInitialized = false;
  }

  // ═══════════════════════════════════════════
  // CREAR SPREADSHEET
  // ═══════════════════════════════════════════

  Future<void> _createSpreadsheet() async {
    if (_sheetsApi == null) return;

    final spreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(
        title: AppConstants.spreadsheetName,
      ),
      sheets: AppConstants.sheetNames.map((name) {
        return sheets.Sheet(
          properties: sheets.SheetProperties(title: name),
        );
      }).toList(),
    );

    final created = await _sheetsApi!.spreadsheets.create(spreadsheet);
    _spreadsheetId = created.spreadsheetId;

    // Guardar ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spreadsheetIdKey, _spreadsheetId!);

    // Escribir encabezados
    await _writeHeaders();
  }

  Future<void> _writeHeaders() async {
    if (_sheetsApi == null || _spreadsheetId == null) return;

    final headers = {
      'Alumnos': [
        'ID', 'Nombre', 'Teléfono', 'Fecha Inscripción', 'Plan',
        'Monto', 'Próximo Pago', 'Estado', 'Cinturón', 'Notas',
        'Creado', 'Actualizado',
      ],
      'Pagos': [
        'ID', 'ID Alumno', 'Nombre Alumno', 'Monto', 'Fecha Pago',
        'Plan', 'Concepto', 'Creado',
      ],
      'Ingresos': [
        'ID', 'Categoría', 'Descripción', 'Monto', 'Fecha',
        'Referencia', 'Creado',
      ],
      'Gastos': [
        'ID', 'Categoría', 'Descripción', 'Monto', 'Fecha',
        'Recurrente', 'Día Recurrente', 'Creado',
      ],
      'Inventario': [
        'ID', 'Nombre', 'Categoría', 'Talla', 'Precio Compra',
        'Precio Venta', 'Stock', 'Descripción', 'Creado', 'Actualizado',
      ],
      'Ventas': [
        'ID', 'ID Producto', 'Producto', 'Cantidad', 'Precio Unitario',
        'Total', 'Fecha', 'Cliente', 'Creado',
      ],
    };

    for (final entry in headers.entries) {
      try {
        await _sheetsApi!.spreadsheets.values.update(
          sheets.ValueRange(values: [entry.value]),
          _spreadsheetId!,
          '${entry.key}!A1',
          valueInputOption: 'RAW',
        );
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════
  // SINCRONIZACIÓN COMPLETA
  // ═══════════════════════════════════════════

  Future<SyncResult> syncAll() async {
    if (!_isInitialized || _sheetsApi == null || _spreadsheetId == null) {
      return SyncResult(success: false, message: 'No conectado a Google Sheets');
    }

    int synced = 0;
    int errors = 0;

    try {
      // Sincronizar alumnos
      final studentRepo = StudentRepository(_db);
      final unsyncedStudents = await studentRepo.getUnsynced();
      for (final student in unsyncedStudents) {
        try {
          await _appendRow('Alumnos', student.toSheetRow());
          await studentRepo.markSynced(student.id);
          synced++;
        } catch (_) {
          errors++;
        }
      }

      // Sincronizar pagos
      final paymentRepo = PaymentRepository(_db);
      final unsyncedPayments = await paymentRepo.getUnsynced();
      for (final payment in unsyncedPayments) {
        try {
          await _appendRow('Pagos', payment.toSheetRow());
          await paymentRepo.markSynced(payment.id);
          synced++;
        } catch (_) {
          errors++;
        }
      }

      // Sincronizar ingresos
      final incomeRepo = IncomeRepository(_db);
      final unsyncedIncomes = await incomeRepo.getUnsynced();
      for (final income in unsyncedIncomes) {
        try {
          await _appendRow('Ingresos', income.toSheetRow());
          await incomeRepo.markSynced(income.id);
          synced++;
        } catch (_) {
          errors++;
        }
      }

      // Sincronizar gastos
      final expenseRepo = ExpenseRepository(_db);
      final unsyncedExpenses = await expenseRepo.getUnsynced();
      for (final expense in unsyncedExpenses) {
        try {
          await _appendRow('Gastos', expense.toSheetRow());
          await expenseRepo.markSynced(expense.id);
          synced++;
        } catch (_) {
          errors++;
        }
      }

      // Sincronizar inventario
      final inventoryRepo = InventoryRepository(_db);
      final unsyncedProducts = await inventoryRepo.getUnsyncedProducts();
      for (final product in unsyncedProducts) {
        try {
          await _appendRow('Inventario', product.toSheetRow());
          await inventoryRepo.markProductSynced(product.id);
          synced++;
        } catch (_) {
          errors++;
        }
      }

      // Sincronizar ventas
      final unsyncedSales = await inventoryRepo.getUnsyncedSales();
      for (final sale in unsyncedSales) {
        try {
          await _appendRow('Ventas', sale.toSheetRow());
          await inventoryRepo.markSaleSynced(sale.id);
          synced++;
        } catch (_) {
          errors++;
        }
      }

      return SyncResult(
        success: true,
        message: '$synced registros sincronizados${errors > 0 ? ', $errors errores' : ''}',
        syncedCount: synced,
        errorCount: errors,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error al sincronizar: $e',
        syncedCount: synced,
        errorCount: errors,
      );
    }
  }

  Future<void> _appendRow(String sheetName, List<String> row) async {
    if (_sheetsApi == null || _spreadsheetId == null) return;

    await _sheetsApi!.spreadsheets.values.append(
      sheets.ValueRange(values: [row]),
      _spreadsheetId!,
      '$sheetName!A:Z',
      valueInputOption: 'RAW',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  // ═══════════════════════════════════════════
  // SINCRONIZACIÓN COMPLETA (REESCRIBIR TODO)
  // ═══════════════════════════════════════════

  Future<SyncResult> fullSync() async {
    if (!_isInitialized || _sheetsApi == null || _spreadsheetId == null) {
      return SyncResult(success: false, message: 'No conectado a Google Sheets');
    }

    try {
      // Limpiar todas las hojas y reescribir
      for (final sheetName in AppConstants.sheetNames) {
        try {
          await _sheetsApi!.spreadsheets.values.clear(
            sheets.ClearValuesRequest(),
            _spreadsheetId!,
            '$sheetName!A:Z',
          );
        } catch (_) {}
      }

      // Reescribir encabezados
      await _writeHeaders();

      // Reescribir todos los datos
      final studentRepo = StudentRepository(_db);
      final students = await studentRepo.getAll();
      for (final s in students) {
        await _appendRow('Alumnos', s.toSheetRow());
        await studentRepo.markSynced(s.id);
      }

      final paymentRepo = PaymentRepository(_db);
      final payments = await paymentRepo.getAll();
      for (final p in payments) {
        await _appendRow('Pagos', p.toSheetRow());
        await paymentRepo.markSynced(p.id);
      }

      final incomeRepo = IncomeRepository(_db);
      final incomes = await incomeRepo.getAll();
      for (final i in incomes) {
        await _appendRow('Ingresos', i.toSheetRow());
        await incomeRepo.markSynced(i.id);
      }

      final expenseRepo = ExpenseRepository(_db);
      final expenses = await expenseRepo.getAll();
      for (final e in expenses) {
        await _appendRow('Gastos', e.toSheetRow());
        await expenseRepo.markSynced(e.id);
      }

      final inventoryRepo = InventoryRepository(_db);
      final products = await inventoryRepo.getAllProducts();
      for (final p in products) {
        await _appendRow('Inventario', p.toSheetRow());
        await inventoryRepo.markProductSynced(p.id);
      }

      final sales = await inventoryRepo.getAllSales();
      for (final s in sales) {
        await _appendRow('Ventas', s.toSheetRow());
        await inventoryRepo.markSaleSynced(s.id);
      }

      final total = students.length + payments.length + incomes.length +
          expenses.length + products.length + sales.length;

      return SyncResult(
        success: true,
        message: 'Sincronización completa: $total registros',
        syncedCount: total,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error en sincronización completa: $e',
      );
    }
  }
}

// ═══════════════════════════════════════════
// MODELOS DE SOPORTE
// ═══════════════════════════════════════════

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int errorCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.errorCount = 0,
  });
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
