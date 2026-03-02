import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/inventory_providers.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class SellProductPage extends ConsumerStatefulWidget {
  final String productId;

  const SellProductPage({super.key, required this.productId});

  @override
  ConsumerState<SellProductPage> createState() => _SellProductPageState();
}

class _SellProductPageState extends ConsumerState<SellProductPage> {
  final _clienteController = TextEditingController();
  int _cantidad = 1;
  bool _isSelling = false;

  @override
  void dispose() {
    _clienteController.dispose();
    super.dispose();
  }

  Future<void> _sell() async {
    setState(() => _isSelling = true);

    try {
      final product = await ref.read(inventoryRepositoryProvider).getProductById(widget.productId);
      if (product == null) throw Exception('Producto no encontrado');
      if (product.stock < _cantidad) throw Exception('Stock insuficiente');

      await ref.read(productsProvider.notifier).sellProduct(
            product: product,
            cantidad: _cantidad,
            clienteNombre: _clienteController.text.trim().isEmpty
                ? null
                : _clienteController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta registrada: ${Formatters.currency(product.precioVenta * _cantidad)}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(inventoryRepositoryProvider).getProductById(widget.productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: LoadingIndicator());
        }

        final product = snapshot.data!;
        final total = product.precioVenta * _cantidad;

        return Scaffold(
          appBar: AppBar(title: const Text('Registrar Venta')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Producto info
              ValhallaCard(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sell, color: AppColors.gold, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.nombre,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${product.categoria} - ${product.talla}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio: ${Formatters.currency(product.precioVenta)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock disponible: ${product.stock}',
                      style: TextStyle(
                        color: product.stockBajo ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cantidad
              ValhallaCard(
                child: Column(
                  children: [
                    const Text('Cantidad', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _cantidad > 1
                              ? () => setState(() => _cantidad--)
                              : null,
                          icon: const Icon(Icons.remove_circle),
                          iconSize: 36,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$_cantidad',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed: _cantidad < product.stock
                              ? () => setState(() => _cantidad++)
                              : null,
                          icon: const Icon(Icons.add_circle),
                          iconSize: 36,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cliente (opcional)
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente (opcional)',
                  prefixIcon: Icon(Icons.person, color: AppColors.gold),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),

              // Total
              ValhallaCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Formatters.currency(total),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSelling ? null : _sell,
                  icon: _isSelling
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isSelling ? 'Procesando...' : 'Confirmar Venta'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
