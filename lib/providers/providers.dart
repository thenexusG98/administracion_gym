import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/data/database/database_helper.dart';
import 'package:valhalla_bjj/data/repositories/student_repository.dart';
import 'package:valhalla_bjj/data/repositories/payment_repository.dart';
import 'package:valhalla_bjj/data/repositories/income_repository.dart';
import 'package:valhalla_bjj/data/repositories/expense_repository.dart';
import 'package:valhalla_bjj/data/repositories/inventory_repository.dart';
import 'package:valhalla_bjj/data/services/google_sheets_service.dart';

// ═══════════════════════════════════════════
// DATABASE
// ═══════════════════════════════════════════
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// ═══════════════════════════════════════════
// REPOSITORIES
// ═══════════════════════════════════════════
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(databaseProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(databaseProvider));
});

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository(ref.watch(databaseProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(databaseProvider));
});

// ═══════════════════════════════════════════
// GOOGLE SHEETS
// ═══════════════════════════════════════════
final googleSheetsServiceProvider = Provider<GoogleSheetsService>((ref) {
  return GoogleSheetsService(db: ref.watch(databaseProvider));
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  return SyncStatus.idle;
});

enum SyncStatus { idle, syncing, success, error }
