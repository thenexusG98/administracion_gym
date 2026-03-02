import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/expense.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/expense_providers.dart';
import 'package:valhalla_bjj/features/expenses/presentation/pages/expense_form_page.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final monthlyTotal = ref.watch(monthlyExpenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💸 Gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _navigateToForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total mensual
          Padding(
            padding: const EdgeInsets.all(16),
            child: ValhallaCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.trending_down, color: AppColors.error, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gastos del mes',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(monthlyTotal.valueOrNull ?? 0),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de gastos
          Expanded(
            child: expensesAsync.when(
              loading: () => const LoadingIndicator(message: 'Cargando gastos...'),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return EmptyState(
                    icon: Icons.money_off,
                    title: 'Sin gastos registrados',
                    subtitle: 'Registra tu primer gasto',
                    buttonText: 'Agregar gasto',
                    onButtonPressed: () => _navigateToForm(context),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: () => ref.read(expensesProvider.notifier).loadExpenses(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      return _ExpenseListTile(
                        expense: expenses[index],
                        onDelete: () => _deleteExpense(context, ref, expenses[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.remove),
        label: const Text('Gasto'),
      ),
    );
  }

  void _navigateToForm(BuildContext context, [String? expenseId]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormPage(expenseId: expenseId)),
    );
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text('¿Eliminar "${expense.descripcion}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(expensesProvider.notifier).deleteExpense(expense.id);
    }
  }
}

class _ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const _ExpenseListTile({required this.expense, required this.onDelete});

  IconData get _categoryIcon {
    switch (expense.categoria) {
      case 'Renta':
        return Icons.home;
      case 'Luz':
        return Icons.bolt;
      case 'Agua':
        return Icons.water_drop;
      case 'Limpieza':
        return Icons.cleaning_services;
      case 'Mantenimiento':
        return Icons.build;
      case 'Compra de inventario':
        return Icons.inventory;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: AppColors.error),
        ),
        onDismissed: (_) => onDelete(),
        child: ValhallaCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.descripcion,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.categoria,
                            style: const TextStyle(fontSize: 10, color: AppColors.redLight),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.date(expense.fecha),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (expense.esRecurrente) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.repeat, size: 14, color: AppColors.warning),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '-${Formatters.currency(expense.monto)}',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
