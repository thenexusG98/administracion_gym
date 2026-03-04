import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/dashboard_providers.dart';
import 'package:valhalla_bjj/providers/student_providers.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return dashboardAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: 16),
            Text('Cargando dashboard...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
      error: (e, st) {
        debugPrint('❌ Dashboard error: $e\n$st');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Error al cargar datos:\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dashboardDataProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      },
      data: (data) {
        final expiringSoonAsync = ref.watch(expiringSoonStudentsProvider);
        return RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          ref.invalidate(dashboardDataProvider);
          ref.invalidate(expiringSoonStudentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ═══ HEADER ═══
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo_valhalla.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valhalla BJJ',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      Formatters.monthYear(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ═══ STATS GRID ═══
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                  title: 'Ingresos',
                  value: Formatters.currency(data.ingresosMes),
                  icon: Icons.trending_up,
                  iconColor: AppColors.success,
                  valueColor: AppColors.success,
                  subtitle: data.variacionIngresos != 0
                      ? '${data.variacionIngresos > 0 ? '+' : ''}${Formatters.percentage(data.variacionIngresos)} vs mes anterior'
                      : null,
                ),
                StatCard(
                  title: 'Gastos',
                  value: Formatters.currency(data.gastosMes),
                  icon: Icons.trending_down,
                  iconColor: AppColors.error,
                  valueColor: AppColors.error,
                  subtitle: data.variacionGastos != 0
                      ? '${data.variacionGastos > 0 ? '+' : ''}${Formatters.percentage(data.variacionGastos)} vs mes anterior'
                      : null,
                ),
                StatCard(
                  title: 'Ganancia Neta',
                  value: Formatters.currency(data.gananciaNeta),
                  icon: Icons.account_balance_wallet,
                  iconColor: AppColors.gold,
                  valueColor: data.gananciaNeta >= 0 ? AppColors.gold : AppColors.error,
                ),
                StatCard(
                  title: 'Alumnos Activos',
                  value: '${data.alumnosActivos}',
                  icon: Icons.people,
                  iconColor: AppColors.info,
                ),
                StatCard(
                  title: 'Ventas Equipo',
                  value: Formatters.currency(data.ventasEquipo),
                  icon: Icons.sell,
                  iconColor: AppColors.goldLight,
                ),
                StatCard(
                  title: 'Más Vendido',
                  value: data.productoMasVendido,
                  icon: Icons.star,
                  iconColor: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ═══ PREDICCIÓN ═══
            if (data.prediccionIngresos > 0)
              ValhallaCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_graph, color: AppColors.gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Predicción fin de mes',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            Formatters.currency(data.prediccionIngresos),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ═══ GRÁFICA INGRESOS VS GASTOS POR CATEGORÍA ═══
            if (data.ingresosPorCategoria.isNotEmpty || data.gastosPorCategoria.isNotEmpty) ...[
              const SectionHeader(title: 'Distribución de Ingresos'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _IncomePieChart(data: data.ingresosPorCategoria),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Distribución de Gastos'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _ExpensePieChart(data: data.gastosPorCategoria),
              ),
              const SizedBox(height: 24),
            ],

            // ═══ RESUMEN FINANCIERO BAR CHART ═══
            const SectionHeader(title: 'Resumen Financiero'),
            const SizedBox(height: 8),
            ValhallaCard(
              child: SizedBox(
                height: 200,
                child: _FinancialBarChart(
                  ingresos: data.ingresosMes,
                  gastos: data.gastosMes,
                  ingresosAnterior: data.ingresosAnterior,
                  gastosAnterior: data.gastosAnterior,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ═══ ALUMNOS POR VENCER ═══
            expiringSoonAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (students) {
                if (students.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    SectionHeader(
                      title: '⚠️ Alumnos por vencer (${students.length})',
                    ),
                    const SizedBox(height: 8),
                    ...students.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ValhallaCard(
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      Formatters.daysRemaining(s.fechaProximoPago),
                                      style: const TextStyle(color: AppColors.warning, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.currency(s.monto),
                                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ═══ TOP PRODUCTOS ═══
            if (data.topProductos.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: '🏆 Top Productos'),
              const SizedBox(height: 8),
              ...data.topProductos.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ValhallaCard(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${data.topProductos.keys.toList().indexOf(entry.key) + 1}',
                              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Text(
                          '${entry.value} vendidos',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      );
      },
    );
  }
}

// ═══════════════════════════════════════════
// GRÁFICAS
// ═══════════════════════════════════════════

class _IncomePieChart extends StatelessWidget {
  final Map<String, double> data;
  const _IncomePieChart({required this.data});

  static const _colors = [
    AppColors.success,
    AppColors.gold,
    AppColors.info,
    AppColors.warning,
    AppColors.redLight,
    AppColors.goldLight,
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: entries.asMap().entries.map((mapEntry) {
                final i = mapEntry.key;
                final entry = mapEntry.value;
                final pct = total > 0 ? (entry.value / total) * 100 : 0;
                return PieChartSectionData(
                  color: _colors[i % _colors.length],
                  value: entry.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((mapEntry) {
            final i = mapEntry.key;
            final entry = mapEntry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ExpensePieChart extends StatelessWidget {
  final Map<String, double> data;
  const _ExpensePieChart({required this.data});

  static const _colors = [
    AppColors.red,
    AppColors.warning,
    AppColors.info,
    AppColors.redLight,
    AppColors.goldDark,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: entries.asMap().entries.map((mapEntry) {
                final i = mapEntry.key;
                final entry = mapEntry.value;
                final pct = total > 0 ? (entry.value / total) * 100 : 0;
                return PieChartSectionData(
                  color: _colors[i % _colors.length],
                  value: entry.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((mapEntry) {
            final i = mapEntry.key;
            final entry = mapEntry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FinancialBarChart extends StatelessWidget {
  final double ingresos;
  final double gastos;
  final double ingresosAnterior;
  final double gastosAnterior;

  const _FinancialBarChart({
    required this.ingresos,
    required this.gastos,
    required this.ingresosAnterior,
    required this.gastosAnterior,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = [ingresos, gastos, ingresosAnterior, gastosAnterior]
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return BarChart(
      BarChartData(
        maxY: maxY > 0 ? maxY : 1000,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final labels = ['Ing. Anterior', 'Gast. Anterior', 'Ingresos', 'Gastos'];
              return BarTooltipItem(
                '${labels[group.x]}\n${Formatters.currency(rod.toY)}',
                const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Ing.\nAnterior', 'Gast.\nAnterior', 'Ingresos', 'Gastos'];
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[idx],
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _bar(0, ingresosAnterior, AppColors.success.withOpacity(0.4)),
          _bar(1, gastosAnterior, AppColors.error.withOpacity(0.4)),
          _bar(2, ingresos, AppColors.success),
          _bar(3, gastos, AppColors.error),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
