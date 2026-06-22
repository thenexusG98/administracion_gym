import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/product_layaway.dart';
import 'package:valhalla_bjj/core/models/abono_producto.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/inventory_providers.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/providers/layaway_providers.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class CreateLayawayPage extends ConsumerStatefulWidget {
  final String productId;

  const CreateLayawayPage({super.key, required this.productId});

  @override
  ConsumerState<CreateLayawayPage> createState() => _CreateLayawayPageState();
}

class _CreateLayawayPageState extends ConsumerState<CreateLayawayPage> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _abonoController = TextEditingController();
  final _notasController = TextEditingController();

  int _cantidad = 1;
  bool _isSaving = false;

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _abonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = await ref.read(inventoryRepositoryProvider).getProductById(widget.productId);
    if (product == null) return;

    final montoAbono = double.tryParse(_abonoController.text.replaceAll(',', '.')) ?? 0;
    final precioTotal = product.precioVenta * _cantidad;

    if (montoAbono <= 0 || montoAbono > precioTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El anticipo debe ser entre \$0.01 y ${Formatters.currency(precioTotal)}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (product.stock < _cantidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock insuficiente'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final layaway = ProductLayaway(
        productId: product.id,
        productName: product.nombre,
        clienteNombre: _clienteController.text.trim(),
        clienteTelefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        cantidad: _cantidad,
        precioUnitario: product.precioVenta,
        precioTotal: precioTotal,
        montoAbonado: montoAbono,
        estado: montoAbono >= precioTotal ? 'Completado' : 'Pendiente',
        fecha: now,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      final primerAbono = AbonoProducto(
        layawayId: layaway.id,
        monto: montoAbono,
        fecha: now,
        notas: 'Anticipo inicial',
      );

      await ref.read(layawaysProvider.notifier).createLayaway(
            layaway: layaway,
            primerAbono: primerAbono,
          );

      if (mounted) {
        final saldo = precioTotal - montoAbono;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saldo <= 0
                  ? '✅ Apartado liquidado y venta registrada'
                  : '✅ Apartado creado. Saldo pendiente: ${Formatters.currency(saldo)}',
            ),
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
      if (mounted) setState(() => _isSaving = false);
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
        final precioTotal = product.precioVenta * _cantidad;
        final abonoTexto = _abonoController.text.replaceAll(',', '.');
        final montoAbono = double.tryParse(abonoTexto) ?? 0;
        final saldo = precioTotal - montoAbono;

        return Scaffold(
          appBar: AppBar(title: const Text('Registrar Apartado')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info del producto
                ValhallaCard(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2, color: AppColors.gold, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.nombre,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${product.categoria} - ${product.talla}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Precio unitario: ${Formatters.currency(product.precioVenta)}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          color: product.stockBajo ? AppColors.warning : AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cantidad
                ValhallaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cantidad', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _cantidad > 1
                                ? () => setState(() => _cantidad--)
                                : null,
                            icon: const Icon(Icons.remove_circle),
                            color: AppColors.gold,
                            iconSize: 32,
                          ),
                          const SizedBox(width: 20),
                          Text(
                            '$_cantidad',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: _cantidad < product.stock
                                ? () => setState(() => _cantidad++)
                                : null,
                            icon: const Icon(Icons.add_circle),
                            color: AppColors.gold,
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Datos del cliente
                TextFormField(
                  controller: _clienteController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cliente *',
                    prefixIcon: Icon(Icons.person, color: AppColors.gold),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del cliente' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: Icon(Icons.phone, color: AppColors.gold),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),

                // Anticipo inicial
                TextFormField(
                  controller: _abonoController,
                  decoration: InputDecoration(
                    labelText: 'Anticipo inicial *',
                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.gold),
                    helperText: 'Total a pagar: ${Formatters.currency(precioTotal)}',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el monto del anticipo';
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes, color: AppColors.gold),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Resumen
                ValhallaCard(
                  child: Column(
                    children: [
                      _summaryRow('Total a pagar', precioTotal, AppColors.textPrimary),
                      const SizedBox(height: 6),
                      _summaryRow('Anticipo', montoAbono, AppColors.success),
                      const Divider(height: 16),
                      _summaryRow(
                        'Saldo pendiente',
                        saldo < 0 ? 0 : saldo,
                        saldo <= 0 ? AppColors.success : AppColors.warning,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.bookmark_add),
                    label: Text(_isSaving ? 'Guardando...' : 'Registrar Apartado'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, double value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          Formatters.currency(value),
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
