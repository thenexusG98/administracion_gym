import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/income_providers.dart';
import 'package:valhalla_bjj/features/income/presentation/pages/income_form_page.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class IncomePage extends ConsumerWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(incomesProvider);
    final dailyTotal = ref.watch(dailyIncomeProvider);
    final weeklyTotal = ref.watch(weeklyIncomeProvider);
    final monthlyTotal = ref.watch(monthlyIncomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Ingresos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _navigateToForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen de totales
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _TotalCard(
                    label: 'Hoy',
                    value: dailyTotal.valueOrNull ?? 0,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TotalCard(
                    label: 'Semana',
                    value: weeklyTotal.valueOrNull ?? 0,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TotalCard(
                    label: 'Mes',
                    value: monthlyTotal.valueOrNull ?? 0,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          // Lista de ingresos
          Expanded(
            child: incomesAsync.when(
              loading: () => const LoadingIndicator(message: 'Cargando ingresos...'),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (incomes) {
                if (incomes.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Sin ingresos registrados',
                    subtitle: 'Registra tu primer ingreso',
                    buttonText: 'Agregar ingreso',
                    onButtonPressed: () => _navigateToForm(context),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: () => ref.read(incomesProvider.notifier).loadIncomes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: incomes.length,
                    itemBuilder: (context, index) {
                      return _IncomeListTile(
                        income: incomes[index],
                        onDelete: () => _deleteIncome(context, ref, incomes[index]),
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
        icon: const Icon(Icons.add),
        label: const Text('Ingreso'),
      ),
    );
  }

  void _navigateToForm(BuildContext context, [String? incomeId]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IncomeFormPage(incomeId: incomeId)),
    );
  }

  Future<void> _deleteIncome(BuildContext context, WidgetRef ref, Income income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Ingreso'),
        content: Text('¿Eliminar "${income.descripcion}"?'),
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
      ref.read(incomesProvider.notifier).deleteIncome(income.id);
    }
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TotalCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ValhallaCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.currency(value),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeListTile extends StatelessWidget {
  final Income income;
  final VoidCallback onDelete;

  const _IncomeListTile({required this.income, required this.onDelete});

  IconData get _categoryIcon {
    switch (income.categoria) {
      case 'Mensualidades':
        return Icons.card_membership;
      case 'Inscripciones':
        return Icons.person_add;
      default:
        if (income.categoria.startsWith('Venta')) return Icons.shopping_bag;
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(income.id),
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
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      income.descripcion,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              income.categoria,
                              style: const TextStyle(fontSize: 10, color: AppColors.gold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.date(income.fecha),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '+${Formatters.currency(income.monto)}',
                style: const TextStyle(
                  color: AppColors.success,
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
