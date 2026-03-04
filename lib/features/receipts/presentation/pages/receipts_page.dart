import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/payment.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/data/services/receipt_service.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class ReceiptsPage extends ConsumerStatefulWidget {
  const ReceiptsPage({super.key});

  @override
  ConsumerState<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends ConsumerState<ReceiptsPage> {
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await ref.read(paymentRepositoryProvider).getAll();
      // Ordenar por fecha más reciente
      payments.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🧾 Recibos de Pago'),
        backgroundColor: AppColors.surface,
      ),
      body: _isLoading
          ? const Center(
              child: LoadingIndicator(message: 'Cargando pagos...'),
            )
          : _payments.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin pagos registrados',
                    subtitle: 'Los recibos aparecerán aquí al registrar pagos',
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return _PaymentReceiptTile(
                        payment: payment,
                        onPreview: () => _previewReceipt(payment),
                        onShare: () => _shareReceipt(payment),
                      );
                    },
                  ),
                ),
    );
  }

  ReceiptData _buildReceiptData(Payment payment) {
    return ReceiptData(
      receiptNumber: payment.id.substring(0, 8).toUpperCase(),
      studentName: payment.studentName,
      studentPhone: '',
      plan: payment.tipoPlan,
      amount: payment.monto,
      paymentDate: payment.fechaPago,
      concept: payment.concepto,
    );
  }

  Future<void> _previewReceipt(Payment payment) async {
    try {
      await ReceiptService().previewReceipt(_buildReceiptData(payment));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar recibo: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _shareReceipt(Payment payment) async {
    try {
      await ReceiptService().shareReceipt(_buildReceiptData(payment));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _PaymentReceiptTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onPreview;
  final VoidCallback onShare;

  const _PaymentReceiptTile({
    required this.payment,
    required this.onPreview,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ValhallaCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              payment.tipoPlan,
                              style: const TextStyle(fontSize: 10, color: AppColors.info),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Formatters.date(payment.fechaPago),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Monto
                Text(
                  Formatters.currency(payment.monto),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),
            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: AppColors.gold),
                  label: const Text('Ver PDF', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 16, color: AppColors.info),
                  label: const Text('Compartir', style: TextStyle(color: AppColors.info, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
