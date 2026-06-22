import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/models/product_layaway.dart';
import 'package:valhalla_bjj/core/models/abono_producto.dart';
import 'package:valhalla_bjj/core/models/sale.dart';
import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/providers/inventory_providers.dart';
import 'package:valhalla_bjj/providers/income_providers.dart';

// ═══════════════════════════════════════════
// APARTADOS / ANTICIPOS
// ═══════════════════════════════════════════
final layawaysProvider =
    StateNotifierProvider<LayawaysNotifier, AsyncValue<List<ProductLayaway>>>(
        (ref) => LayawaysNotifier(ref));

class LayawaysNotifier extends StateNotifier<AsyncValue<List<ProductLayaway>>> {
  final Ref _ref;

  LayawaysNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadLayaways();
  }

  Future<void> loadLayaways() async {
    state = const AsyncValue.loading();
    try {
      final layaways = await _ref.read(layawayRepositoryProvider).getAll();
      state = AsyncValue.data(layaways);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Crea un nuevo apartado con el primer abono/anticipo.
  Future<void> createLayaway({
    required ProductLayaway layaway,
    required AbonoProducto primerAbono,
  }) async {
    try {
      final layawayRepo = _ref.read(layawayRepositoryProvider);
      final invRepo = _ref.read(inventoryRepositoryProvider);

      // Guardar apartado y primer abono
      await layawayRepo.saveLayaway(layaway);
      await layawayRepo.saveAbono(primerAbono);

      // Descontar stock (reservar el artículo)
      await invRepo.decrementStock(layaway.productId, layaway.cantidad);

      // Registrar ingreso por el anticipo
      final income = Income(
        categoria: 'Anticipo - Inventario',
        descripcion:
            'Anticipo: ${layaway.productName} (x${layaway.cantidad}) - ${layaway.clienteNombre}',
        monto: primerAbono.monto,
        fecha: primerAbono.fecha,
        referenceId: layaway.id,
      );
      await _ref.read(incomeRepositoryProvider).save(income);

      // Refrescar
      await loadLayaways();
      _ref.read(productsProvider.notifier).loadProducts();
      _ref.read(incomesProvider.notifier).loadIncomes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Agrega un abono a un apartado existente.
  /// Si el total queda liquidado, lo marca como Completado y registra la venta.
  Future<void> addAbono({
    required ProductLayaway layaway,
    required AbonoProducto abono,
  }) async {
    try {
      final layawayRepo = _ref.read(layawayRepositoryProvider);

      // Guardar abono
      await layawayRepo.saveAbono(abono);

      // Calcular nuevo total abonado
      final newMontoAbonado = layaway.montoAbonado + abono.monto;
      final isComplete = newMontoAbonado >= layaway.precioTotal;

      // Actualizar apartado
      final updatedLayaway = layaway.copyWith(
        montoAbonado: newMontoAbonado,
        estado: isComplete ? 'Completado' : 'Pendiente',
      );
      await layawayRepo.updateLayaway(updatedLayaway);

      // Registrar ingreso por el abono
      final income = Income(
        categoria: isComplete ? 'Venta - Inventario' : 'Anticipo - Inventario',
        descripcion:
            '${isComplete ? "Pago final" : "Abono"}: ${layaway.productName} - ${layaway.clienteNombre}',
        monto: abono.monto,
        fecha: abono.fecha,
        referenceId: layaway.id,
      );
      await _ref.read(incomeRepositoryProvider).save(income);

      // Si está liquidado, registrar la venta en el historial de ventas
      if (isComplete) {
        final sale = Sale(
          productId: layaway.productId,
          productName: layaway.productName,
          cantidad: layaway.cantidad,
          precioUnitario: layaway.precioUnitario,
          total: layaway.precioTotal,
          fecha: abono.fecha,
          clienteNombre: layaway.clienteNombre,
        );
        await _ref.read(inventoryRepositoryProvider).saveSale(sale);
      }

      // Refrescar
      await loadLayaways();
      _ref.read(incomesProvider.notifier).loadIncomes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Cancela un apartado y restaura el stock del producto.
  Future<void> cancelLayaway(ProductLayaway layaway) async {
    try {
      final invRepo = _ref.read(inventoryRepositoryProvider);

      // Restaurar stock
      final product = await invRepo.getProductById(layaway.productId);
      if (product != null) {
        await invRepo.updateProduct(
          product.copyWith(stock: product.stock + layaway.cantidad),
        );
      }

      // Marcar como cancelado
      await _ref
          .read(layawayRepositoryProvider)
          .updateLayaway(layaway.copyWith(estado: 'Cancelado'));

      // Refrescar
      await loadLayaways();
      _ref.read(productsProvider.notifier).loadProducts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ═══════════════════════════════════════════
// PROVIDERS AUXILIARES
// ═══════════════════════════════════════════

final pendingLayawaysProvider = FutureProvider<List<ProductLayaway>>((ref) async {
  ref.watch(layawaysProvider);
  return ref.read(layawayRepositoryProvider).getPending();
});

final layawaysByProductProvider =
    FutureProvider.family<List<ProductLayaway>, String>((ref, productId) async {
  ref.watch(layawaysProvider);
  return ref.read(layawayRepositoryProvider).getPendingByProduct(productId);
});

final layawayAbonosProvider =
    FutureProvider.family<List<AbonoProducto>, String>((ref, layawayId) async {
  ref.watch(layawaysProvider);
  return ref.read(layawayRepositoryProvider).getAbonosByLayaway(layawayId);
});
