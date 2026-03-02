import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/models/product.dart';
import 'package:valhalla_bjj/core/models/sale.dart';
import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/core/utils/date_extensions.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/providers/income_providers.dart';

// ═══════════════════════════════════════════
// PRODUCTOS
// ═══════════════════════════════════════════
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier(ref);
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final Ref _ref;

  ProductsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _ref.read(inventoryRepositoryProvider).getAllProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _ref.read(inventoryRepositoryProvider).saveProduct(product);
      await loadProducts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _ref.read(inventoryRepositoryProvider).updateProduct(product);
      await loadProducts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _ref.read(inventoryRepositoryProvider).deleteProduct(id);
      await loadProducts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sellProduct({
    required Product product,
    required int cantidad,
    String? clienteNombre,
  }) async {
    try {
      final sale = Sale(
        productId: product.id,
        productName: product.nombre,
        cantidad: cantidad,
        precioUnitario: product.precioVenta,
        total: product.precioVenta * cantidad,
        fecha: DateTime.now(),
        clienteNombre: clienteNombre,
      );

      // Registrar venta
      await _ref.read(inventoryRepositoryProvider).saveSale(sale);

      // Descontar stock
      await _ref.read(inventoryRepositoryProvider).decrementStock(product.id, cantidad);

      // Registrar ingreso automático
      final income = Income(
        categoria: 'Venta de ${product.categoria.toLowerCase()}',
        descripcion: '${product.nombre} x$cantidad',
        monto: sale.total,
        fecha: DateTime.now(),
        referenceId: sale.id,
      );
      await _ref.read(incomeRepositoryProvider).save(income);

      // Refrescar
      await loadProducts();
      _ref.read(incomesProvider.notifier).loadIncomes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ═══════════════════════════════════════════
// PRODUCTOS CON STOCK BAJO
// ═══════════════════════════════════════════
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(productsProvider);
  return ref.read(inventoryRepositoryProvider).getLowStockProducts();
});

// ═══════════════════════════════════════════
// VENTAS
// ═══════════════════════════════════════════
final salesProvider = FutureProvider<List<Sale>>((ref) async {
  ref.watch(productsProvider);
  return ref.read(inventoryRepositoryProvider).getAllSales();
});

final monthlySalesProvider = FutureProvider<double>((ref) async {
  ref.watch(productsProvider);
  final now = DateTime.now();
  return ref.read(inventoryRepositoryProvider).getSalesTotalByDateRange(
        now.startOfMonth,
        now.endOfMonth,
      );
});

final topSellingProductsProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(productsProvider);
  return ref.read(inventoryRepositoryProvider).getTopSellingProducts();
});
