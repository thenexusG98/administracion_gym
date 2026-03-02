import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/product.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/inventory_providers.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/product_form_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/sell_product_page.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🥋 Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _navigateToForm(context),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const LoadingIndicator(message: 'Cargando inventario...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Inventario vacío',
              subtitle: 'Agrega tu primer producto',
              buttonText: 'Agregar producto',
              onButtonPressed: () => _navigateToForm(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Alertas de stock bajo
              lowStockAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (lowStock) {
                  if (lowStock.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ValhallaCard(
                      color: AppColors.warning.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: AppColors.warning, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '⚠️ Stock bajo',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${lowStock.length} producto(s) con poco stock',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Lista de productos
              ...products.map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ProductCard(
                      product: product,
                      onTap: () => _navigateToSell(context, product),
                      onEdit: () => _navigateToForm(context, product.id),
                      onDelete: () => _deleteProduct(context, ref, product),
                    ),
                  )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Producto'),
      ),
    );
  }

  void _navigateToForm(BuildContext context, [String? productId]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(productId: productId)),
    );
  }

  void _navigateToSell(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellProductPage(productId: product.id)),
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "${product.nombre}"?'),
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
      ref.read(productsProvider.notifier).deleteProduct(product.id);
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ValhallaCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              // Icono del producto
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon,
                  color: AppColors.gold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nombre,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${product.categoria} • ${product.talla}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: product.stockBajo
                      ? AppColors.warning.withOpacity(0.15)
                      : AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    color: product.stockBajo ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _priceColumn('Compra', product.precioCompra, AppColors.textSecondary),
              _priceColumn('Venta', product.precioVenta, AppColors.gold),
              _priceColumn('Ganancia', product.ganancia, AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: product.stock > 0 ? onTap : null,
                  icon: const Icon(Icons.sell, size: 16),
                  label: const Text('Vender'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _categoryIcon {
    switch (product.categoria) {
      case 'Playera':
        return Icons.checkroom;
      case 'Rashguard':
        return Icons.checkroom;
      case 'Gi (Kimono)':
        return Icons.sports_martial_arts;
      case 'Shorts':
        return Icons.checkroom;
      case 'Cinturón':
        return Icons.horizontal_rule;
      case 'Suplemento':
        return Icons.local_pharmacy;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _priceColumn(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 2),
        Text(
          Formatters.currency(value),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
