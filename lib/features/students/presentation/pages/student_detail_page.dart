import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/student.dart';
import 'package:valhalla_bjj/core/models/payment.dart';
import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/providers/student_providers.dart';
import 'package:valhalla_bjj/providers/income_providers.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/student_form_page.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class StudentDetailPage extends ConsumerStatefulWidget {
  final String studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage> {
  Student? _student;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    final student = await ref.read(studentRepositoryProvider).getById(widget.studentId);
    if (mounted) setState(() => _student = student);
  }

  Future<void> _registerPayment() async {
    if (_student == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Text(
          '¿Registrar pago de ${Formatters.currency(_student!.monto)} para ${_student!.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final payment = Payment(
      studentId: _student!.id,
      studentName: _student!.nombre,
      monto: _student!.monto,
      fechaPago: DateTime.now(),
      tipoPlan: _student!.tipoPlan,
    );

    await ref.read(paymentRepositoryProvider).save(payment);

    // Registrar como ingreso
    final income = Income(
      categoria: 'Mensualidades',
      descripcion: 'Pago de ${_student!.nombre} - ${_student!.tipoPlan}',
      monto: _student!.monto,
      fecha: DateTime.now(),
      referenceId: payment.id,
    );
    await ref.read(incomeRepositoryProvider).save(income);

    // Actualizar fecha de próximo pago
    final diasPlan = _student!.tipoPlan == 'Mensual'
        ? 30
        : _student!.tipoPlan == 'Quincenal'
            ? 15
            : 0;

    if (diasPlan > 0) {
      final updatedStudent = _student!.copyWith(
        fechaProximoPago: DateTime.now().add(Duration(days: diasPlan)),
        estado: 'Activo',
      );
      await ref.read(studentsProvider.notifier).updateStudent(updatedStudent);
    }

    ref.read(incomesProvider.notifier).loadIncomes();
    ref.invalidate(studentPaymentsProvider(widget.studentId));
    await _loadStudent();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pago registrado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteStudent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alumno'),
        content: Text('¿Eliminar a ${_student?.nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(studentsProvider.notifier).deleteStudent(widget.studentId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_student == null) {
      return const Scaffold(body: LoadingIndicator());
    }

    final paymentsAsync = ref.watch(studentPaymentsProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_student!.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentFormPage(studentId: widget.studentId),
                ),
              );
              _loadStudent();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: _deleteStudent,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info principal
          ValhallaCard(
            child: Column(
              children: [
                // Avatar grande
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.sports_martial_arts,
                    size: 40,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _student!.nombre,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cinturón ${_student!.cinturon}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _infoRow('📱', 'Teléfono', _student!.telefono),
                _infoRow('📋', 'Plan', _student!.tipoPlan),
                _infoRow('💰', 'Monto', Formatters.currency(_student!.monto)),
                _infoRow('📅', 'Inscripción', Formatters.date(_student!.fechaInscripcion)),
                _infoRow('⏰', 'Próximo pago', Formatters.date(_student!.fechaProximoPago)),
                _infoRow('🔖', 'Estado', _student!.estado),
                if (_student!.notas != null && _student!.notas!.isNotEmpty)
                  _infoRow('📝', 'Notas', _student!.notas!),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botón de pago
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _registerPayment,
              icon: const Icon(Icons.payment),
              label: Text('Registrar Pago - ${Formatters.currency(_student!.monto)}'),
            ),
          ),
          const SizedBox(height: 24),

          // Historial de pagos
          const SectionHeader(title: 'Historial de Pagos'),
          const SizedBox(height: 8),

          paymentsAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (payments) {
              if (payments.isEmpty) {
                return const ValhallaCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sin pagos registrados',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: payments.map((p) => _paymentTile(p)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentTile(Payment payment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ValhallaCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.concepto, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    Formatters.date(payment.fechaPago),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}
