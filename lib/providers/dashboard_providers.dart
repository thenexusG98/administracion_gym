import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/utils/date_extensions.dart';
import 'package:valhalla_bjj/providers/providers.dart';

class DashboardData {
  final double ingresosMes;
  final double gastosMes;
  final double gananciaNeta;
  final int alumnosActivos;
  final double ventasEquipo;
  final String productoMasVendido;
  final double ingresosAnterior;
  final double gastosAnterior;
  final Map<String, double> ingresosPorCategoria;
  final Map<String, double> gastosPorCategoria;
  final Map<String, int> topProductos;

  DashboardData({
    required this.ingresosMes,
    required this.gastosMes,
    required this.gananciaNeta,
    required this.alumnosActivos,
    required this.ventasEquipo,
    required this.productoMasVendido,
    required this.ingresosAnterior,
    required this.gastosAnterior,
    required this.ingresosPorCategoria,
    required this.gastosPorCategoria,
    required this.topProductos,
  });

  double get variacionIngresos =>
      ingresosAnterior > 0 ? ((ingresosMes - ingresosAnterior) / ingresosAnterior) * 100 : 0;

  double get variacionGastos =>
      gastosAnterior > 0 ? ((gastosMes - gastosAnterior) / gastosAnterior) * 100 : 0;

  double get prediccionIngresos {
    final now = DateTime.now();
    final diasTranscurridos = now.day;
    final diasEnMes = DateTime(now.year, now.month + 1, 0).day;
    if (diasTranscurridos == 0) return 0;
    return (ingresosMes / diasTranscurridos) * diasEnMes;
  }
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  debugPrint('📊 Cargando datos del dashboard...');

  try {
    final now = DateTime.now();
    final startOfMonth = now.startOfMonth;
    final endOfMonth = now.endOfMonth;

    // Mes anterior
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final startOfPrevMonth = prevMonth.startOfMonth;
    final endOfPrevMonth = prevMonth.endOfMonth;

    final incomeRepo = ref.read(incomeRepositoryProvider);
    final expenseRepo = ref.read(expenseRepositoryProvider);
    final studentRepo = ref.read(studentRepositoryProvider);
    final inventoryRepo = ref.read(inventoryRepositoryProvider);

    debugPrint('📊 Consultando ingresos del mes...');
    final ingresosMes = await incomeRepo.getTotalByDateRange(startOfMonth, endOfMonth);
    debugPrint('📊 Ingresos: $ingresosMes');

    debugPrint('📊 Consultando gastos del mes...');
    final gastosMes = await expenseRepo.getTotalByDateRange(startOfMonth, endOfMonth);
    debugPrint('📊 Gastos: $gastosMes');

    debugPrint('📊 Consultando alumnos activos...');
    final alumnosActivos = await studentRepo.getActiveCount();
    debugPrint('📊 Alumnos activos: $alumnosActivos');

    debugPrint('📊 Consultando ventas equipo...');
    final ventasEquipo = await inventoryRepo.getSalesTotalByDateRange(startOfMonth, endOfMonth);
    debugPrint('📊 Ventas equipo: $ventasEquipo');

    debugPrint('📊 Consultando top productos...');
    final topProductos = await inventoryRepo.getTopSellingProducts();
    debugPrint('📊 Top productos: ${topProductos.length}');

    debugPrint('📊 Consultando mes anterior...');
    final ingresosAnterior = await incomeRepo.getTotalByDateRange(startOfPrevMonth, endOfPrevMonth);
    final gastosAnterior = await expenseRepo.getTotalByDateRange(startOfPrevMonth, endOfPrevMonth);
    debugPrint('📊 Mes anterior OK');

    debugPrint('📊 Consultando categorías...');
    final ingresosPorCategoria = await incomeRepo.getTotalsByCategoria(startOfMonth, endOfMonth);
    final gastosPorCategoria = await expenseRepo.getTotalsByCategoria(startOfMonth, endOfMonth);
    debugPrint('📊 Categorías OK');

    final productoMasVendido = topProductos.isNotEmpty ? topProductos.keys.first : 'N/A';

    debugPrint('📊 ✅ Dashboard datos cargados OK');
    return DashboardData(
      ingresosMes: ingresosMes,
      gastosMes: gastosMes,
      gananciaNeta: ingresosMes - gastosMes,
      alumnosActivos: alumnosActivos,
      ventasEquipo: ventasEquipo,
      productoMasVendido: productoMasVendido,
      ingresosAnterior: ingresosAnterior,
      gastosAnterior: gastosAnterior,
      ingresosPorCategoria: ingresosPorCategoria,
      gastosPorCategoria: gastosPorCategoria,
      topProductos: topProductos,
    );
  } catch (e, st) {
    debugPrint('📊 ❌ ERROR en dashboard: $e');
    debugPrint('📊 ❌ StackTrace: $st');
    rethrow;
  }
});
