import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/core/utils/date_extensions.dart';
import 'package:valhalla_bjj/providers/providers.dart';

// ═══════════════════════════════════════════
// LISTA DE INGRESOS
// ═══════════════════════════════════════════
final incomesProvider = StateNotifierProvider<IncomesNotifier, AsyncValue<List<Income>>>((ref) {
  return IncomesNotifier(ref);
});

class IncomesNotifier extends StateNotifier<AsyncValue<List<Income>>> {
  final Ref _ref;

  IncomesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadIncomes();
  }

  Future<void> loadIncomes() async {
    state = const AsyncValue.loading();
    try {
      final incomes = await _ref.read(incomeRepositoryProvider).getAll();
      state = AsyncValue.data(incomes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addIncome(Income income) async {
    try {
      await _ref.read(incomeRepositoryProvider).save(income);
      await loadIncomes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      await _ref.read(incomeRepositoryProvider).update(income);
      await loadIncomes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _ref.read(incomeRepositoryProvider).delete(id);
      await loadIncomes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ═══════════════════════════════════════════
// TOTALES
// ═══════════════════════════════════════════
final dailyIncomeProvider = FutureProvider<double>((ref) async {
  ref.watch(incomesProvider);
  final now = DateTime.now();
  return ref.read(incomeRepositoryProvider).getDailyTotal(now);
});

final weeklyIncomeProvider = FutureProvider<double>((ref) async {
  ref.watch(incomesProvider);
  final now = DateTime.now();
  return ref.read(incomeRepositoryProvider).getTotalByDateRange(
        now.startOfWeek,
        now.endOfWeek,
      );
});

final monthlyIncomeProvider = FutureProvider<double>((ref) async {
  ref.watch(incomesProvider);
  final now = DateTime.now();
  return ref.read(incomeRepositoryProvider).getTotalByDateRange(
        now.startOfMonth,
        now.endOfMonth,
      );
});

final incomeByCategoryProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(incomesProvider);
  final now = DateTime.now();
  return ref.read(incomeRepositoryProvider).getTotalsByCategoria(
        now.startOfMonth,
        now.endOfMonth,
      );
});
