import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/models/expense.dart';
import 'package:valhalla_bjj/core/utils/date_extensions.dart';
import 'package:valhalla_bjj/providers/providers.dart';

// ═══════════════════════════════════════════
// LISTA DE GASTOS
// ═══════════════════════════════════════════
final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpensesNotifier(ref);
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref _ref;

  ExpensesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _ref.read(expenseRepositoryProvider).getAll();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _ref.read(expenseRepositoryProvider).save(expense);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _ref.read(expenseRepositoryProvider).update(expense);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _ref.read(expenseRepositoryProvider).delete(id);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ═══════════════════════════════════════════
// TOTALES
// ═══════════════════════════════════════════
final monthlyExpenseProvider = FutureProvider<double>((ref) async {
  ref.watch(expensesProvider);
  final now = DateTime.now();
  return ref.read(expenseRepositoryProvider).getTotalByDateRange(
        now.startOfMonth,
        now.endOfMonth,
      );
});

final expenseByCategoryProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(expensesProvider);
  final now = DateTime.now();
  return ref.read(expenseRepositoryProvider).getTotalsByCategoria(
        now.startOfMonth,
        now.endOfMonth,
      );
});
