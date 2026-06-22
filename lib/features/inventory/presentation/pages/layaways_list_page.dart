import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/product_layaway.dart';
import 'package:valhalla_bjj/core/models/abono_producto.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/layaway_providers.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class LayawaysListPage extends ConsumerStatefulWidget {
  const LayawaysListPage({super.key});

  @override
  ConsumerState<LayawaysListPage> createState() => _LayawaysListPageState();
}

class _LayawaysListPageState extends ConsumerState<LayawaysListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layawaysAsync = ref.watch(layawaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏷️ Apartados'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Completados'),
            Tab(text: 'Cancelados'),
          ],
        ),
      ),
      body: layawaysAsync.when(
        loading: () => const LoadingIndicator(message: 'Cargando apartados...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (layaways) {
          final pendientes = layaways.where((l) => l.pendiente).toList();
          final completados = layaways.where((l) => l.completado).toList();
          final cancelados = layaways.where((l) => l.cancelado).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _LayawayList(
                layaways: pendientes,
                emptyTitle: 'Sin apartados pendientes',
                emptySubtitle: 'Los apartados activos aparecerán aquí',
              ),
              _LayawayList(
                layaways: completados,
                emptyTitle: 'Sin apartados liquidados',
                emptySubtitle: 'Los artículos pagados en su totalidad aparecerán aquí',
              ),
              _LayawayList(
                layaways: cancelados,
                emptyTitle: 'Sin apartados cancelados',
                emptySubtitle: '',
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Lista de apartados
// ─────────────────────────────────────────────
class _LayawayList extends StatelessWidget {
  final List<ProductLayaway> layaways;
  final String emptyTitle;
  final String emptySubtitle;

  const _LayawayList({
    required this.layaways,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (layaways.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(emptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (emptySubtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(emptySubtitle,
                  style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: layaways.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _LayawayCard(layaway: layaways[index]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tarjeta de apartado
// ─────────────────────────────────────────────
class _LayawayCard extends ConsumerWidget {
  final ProductLayaway layaway;

  const _LayawayCard({required this.layaway});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final porcentaje = layaway.porcentajePagado;

    return ValhallaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _estadoColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_estadoIcon, color: _estadoColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layaway.productName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${layaway.clienteNombre}${layaway.clienteTelefono != null ? " • ${layaway.clienteTelefono}" : ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _EstadoBadge(estado: layaway.estado),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso
          if (layaway.pendiente) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(porcentaje * 100).toStringAsFixed(0)}% pagado',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Saldo: ${Formatters.currency(layaway.saldo)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentaje,
                backgroundColor: AppColors.divider,
                color: AppColors.gold,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Montos
          Row(
            children: [
              _amountChip('Total', layaway.precioTotal, AppColors.textSecondary),
              const SizedBox(width: 8),
              _amountChip('Abonado', layaway.montoAbonado, AppColors.success),
              if (layaway.pendiente) ...[
                const SizedBox(width: 8),
                _amountChip('Saldo', layaway.saldo, AppColors.warning),
              ],
            ],
          ),

          // Cant. y fecha
          const SizedBox(height: 8),
          Text(
            'Cantidad: ${layaway.cantidad}  •  ${Formatters.date(layaway.fecha)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          if (layaway.notas != null && layaway.notas!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              layaway.notas!,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],

          // Botones (solo para pendientes)
          if (layaway.pendiente) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddAbonoSheet(context, ref, layaway),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Abonar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showHistorySheet(context, ref, layaway),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Historial'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmCancel(context, ref, layaway),
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
                  tooltip: 'Cancelar apartado',
                ),
              ],
            ),
          ],

          // Solo historial para completados/cancelados
          if (!layaway.pendiente)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showHistorySheet(context, ref, layaway),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Ver historial'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _amountChip(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            const SizedBox(height: 2),
            Text(
              Formatters.currency(value),
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Color get _estadoColor {
    switch (layaway.estado) {
      case 'Completado':
        return AppColors.success;
      case 'Cancelado':
        return AppColors.error;
      default:
        return AppColors.gold;
    }
  }

  IconData get _estadoIcon {
    switch (layaway.estado) {
      case 'Completado':
        return Icons.check_circle;
      case 'Cancelado':
        return Icons.cancel;
      default:
        return Icons.bookmark;
    }
  }

  void _showAddAbonoSheet(BuildContext context, WidgetRef ref, ProductLayaway layaway) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAbonoSheet(layaway: layaway, ref: ref),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref, ProductLayaway layaway) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AbonoHistorySheet(layaway: layaway, ref: ref),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, ProductLayaway layaway) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Apartado'),
        content: Text(
          '¿Cancelar el apartado de "${layaway.productName}" para ${layaway.clienteNombre}?\n\n'
          'El stock será restaurado. Los abonos registrados como ingreso no se revertirán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(layawaysProvider.notifier).cancelLayaway(layaway);
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom sheet: agregar abono
// ─────────────────────────────────────────────
class _AddAbonoSheet extends StatefulWidget {
  final ProductLayaway layaway;
  final WidgetRef ref;

  const _AddAbonoSheet({required this.layaway, required this.ref});

  @override
  State<_AddAbonoSheet> createState() => _AddAbonoSheetState();
}

class _AddAbonoSheetState extends State<_AddAbonoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _montoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
    final saldoActual = widget.layaway.saldo;

    if (monto > saldoActual + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El abono no puede ser mayor al saldo: ${Formatters.currency(saldoActual)}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final abono = AbonoProducto(
        layawayId: widget.layaway.id,
        monto: monto,
        fecha: DateTime.now(),
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      await widget.ref.read(layawaysProvider.notifier).addAbono(
            layaway: widget.layaway,
            abono: abono,
          );

      if (mounted) {
        Navigator.pop(context);
        final nuevoSaldo = saldoActual - monto;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoSaldo <= 0
                  ? '✅ ¡Apartado liquidado! Venta registrada.'
                  : '✅ Abono registrado. Saldo restante: ${Formatters.currency(nuevoSaldo)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Registrar Abono', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${widget.layaway.productName} • ${widget.layaway.clienteNombre}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Resumen rápido
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoItem('Total', Formatters.currency(widget.layaway.precioTotal)),
                  _infoItem('Abonado', Formatters.currency(widget.layaway.montoAbonado)),
                  _infoItem('Saldo', Formatters.currency(widget.layaway.saldo),
                      color: AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _montoController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Monto del abono *',
                prefixIcon: const Icon(Icons.attach_money, color: AppColors.gold),
                helperText: 'Saldo pendiente: ${Formatters.currency(widget.layaway.saldo)}',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
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
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
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
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'Guardando...' : 'Registrar Abono'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, {Color color = AppColors.textPrimary}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Bottom sheet: historial de abonos
// ─────────────────────────────────────────────
class _AbonoHistorySheet extends ConsumerWidget {
  final ProductLayaway layaway;
  final WidgetRef ref;

  const _AbonoHistorySheet({required this.layaway, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abonosAsync = ref.watch(layawayAbonosProvider(layaway.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Historial de Abonos', style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${layaway.productName} • ${layaway.clienteNombre}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: abonosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (abonos) {
                    if (abonos.isEmpty) {
                      return const Center(
                        child: Text('Sin abonos registrados',
                            style: TextStyle(color: AppColors.textHint)),
                      );
                    }
                    return ListView.separated(
                      controller: controller,
                      itemCount: abonos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final abono = abonos[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                    color: AppColors.success, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          title: Text(
                            Formatters.currency(abono.monto),
                            style: const TextStyle(
                                color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${Formatters.date(abono.fecha)}${abono.notas != null ? " • ${abono.notas}" : ""}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Badge de estado
// ─────────────────────────────────────────────
class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (estado) {
      case 'Completado':
        color = AppColors.success;
        break;
      case 'Cancelado':
        color = AppColors.error;
        break;
      default:
        color = AppColors.gold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        estado,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
