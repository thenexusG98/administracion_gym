import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/dashboard_providers.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class MonthlyHistoryPage extends ConsumerWidget {
  const MonthlyHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(monthlyHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Historial Mensual'),
      ),
      body: historyAsync.when(
        loading: () => const LoadingIndicator(message: 'Cargando historial...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (months) {
          if (months.isEmpty) {
            return const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'Sin movimientos',
              subtitle: 'Aún no hay ingresos ni gastos registrados',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final m = months[index];
              return _MonthCard(
                summary: m,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _MonthDetailPage(summary: m),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Tarjeta de resumen mensual
// ─────────────────────────────────────────────────
class _MonthCard extends StatelessWidget {
  final MonthSummary summary;
  final VoidCallback onTap;

  const _MonthCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ganancia = summary.ganancia;
    final isPositive = ganancia >= 0;

    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título mes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.monthYear(summary.startDate),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.currency(ganancia),
                        style: TextStyle(
                          color: isPositive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fila ingresos / gastos
              Row(
                children: [
                  _StatChip(
                    label: 'Ingresos',
                    value: Formatters.currency(summary.ingresos),
                    color: AppColors.success,
                    icon: Icons.arrow_upward,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Gastos',
                    value: Formatters.currency(summary.gastos),
                    color: AppColors.error,
                    icon: Icons.arrow_downward,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver detalle →',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(value,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Página de detalle de un mes
// ─────────────────────────────────────────────────
class _MonthDetailPage extends ConsumerWidget {
  final MonthSummary summary;

  const _MonthDetailPage({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(monthDetailProvider(summary.key));

    return Scaffold(
      appBar: AppBar(
        title: Text(Formatters.monthYear(summary.startDate)),
      ),
      body: detailAsync.when(
        loading: () => const LoadingIndicator(message: 'Cargando...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          final ganancia = summary.ganancia;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Resumen superior ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      Formatters.monthYear(summary.startDate),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Ingresos',
                          value: Formatters.currency(summary.ingresos),
                          color: AppColors.success,
                          icon: Icons.arrow_upward,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Gastos',
                          value: Formatters.currency(summary.gastos),
                          color: AppColors.error,
                          icon: Icons.arrow_downward,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: (ganancia >= 0 ? AppColors.success : AppColors.error)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Ganancia neta',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.currency(ganancia),
                            style: TextStyle(
                              color: ganancia >= 0 ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Ingresos por categoría ──
              if (detail.incomesByCategory.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionHeader(
                    title: 'Ingresos por categoría', color: AppColors.success),
                const SizedBox(height: 8),
                ...detail.incomesByCategory.entries
                    .toList()
                  ..sort((a, b) => b.value.compareTo(a.value))
                  ..map((e) => _CategoryRow(
                        name: e.key,
                        amount: e.value,
                        color: AppColors.success,
                      ))
                    .forEach((w) => w is Widget ? null : null),
                for (final e in (detail.incomesByCategory.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value))))
                  _CategoryRow(
                      name: e.key, amount: e.value, color: AppColors.success),
              ],

              // ── Gastos por categoría ──
              if (detail.expensesByCategory.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionHeader(
                    title: 'Gastos por categoría', color: AppColors.error),
                const SizedBox(height: 8),
                for (final e in (detail.expensesByCategory.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value))))
                  _CategoryRow(
                      name: e.key, amount: e.value, color: AppColors.error),
              ],

              // ── Lista de ingresos ──
              if (detail.incomes.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Ingresos (${detail.incomes.length})',
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                ...detail.incomes.map(
                  (inc) => _RecordTile(
                    title: inc.descripcion,
                    subtitle:
                        '${inc.categoria} • ${Formatters.date(inc.fecha)}',
                    amount: inc.monto,
                    isIncome: true,
                  ),
                ),
              ],

              // ── Lista de gastos ──
              if (detail.expenses.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Gastos (${detail.expenses.length})',
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                ...detail.expenses.map(
                  (exp) => _RecordTile(
                    title: exp.descripcion,
                    subtitle:
                        '${exp.categoria} • ${Formatters.date(exp.fecha)}',
                    amount: exp.monto,
                    isIncome: false,
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: color,
            margin: const EdgeInsets.only(right: 8)),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final Color color;

  const _CategoryRow(
      {required this.name, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(name,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          Text(
            Formatters.currency(amount),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;

  const _RecordTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${Formatters.currency(amount)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
