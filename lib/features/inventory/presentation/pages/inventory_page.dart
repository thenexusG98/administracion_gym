import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/product.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/inventory_providers.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/product_form_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/sell_product_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/create_layaway_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/layaways_list_page.dart';
import 'package:valhalla_bjj/providers/layaway_providers.dart';
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
          // Badge de apartados pendientes
          Consumer(
            builder: (context, ref, _) {
              final pendingAsync = ref.watch(pendingLayawaysProvider);
              final count = pendingAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bookmarks_outlined),
                    tooltip: 'Ver apartados',
                    onPressed: () => _navigateToLayaways(context),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
                      onLayaway: () => _navigateToLayaway(context, product),
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

  void _navigateToLayaway(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateLayawayPage(productId: product.id)),
    );
  }

  void _navigateToLayaways(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LayawaysListPage()),
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

class _ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLayaway;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onLayaway,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layawaysAsync = ref.watch(layawaysByProductProvider(product.id));
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
          // Apartados pendientes para este producto
          layawaysAsync.maybeWhen(
            data: (layaways) {
              if (layaways.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark, color: AppColors.gold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Apartado${layaways.length > 1 ? 's (${layaways.length})' : ''}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...layaways.map((l) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    '• ${l.clienteNombre}${l.clienteTelefono != null ? '  ${l.clienteTelefono}' : ''}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Saldo: ${Formatters.currency(l.saldo)}',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
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
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: product.stock > 0 ? onTap : null,
                  icon: const Icon(Icons.sell, size: 16),
                  label: const Text('Vender'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: product.stock > 0 ? onLayaway : null,
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('Apartar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
