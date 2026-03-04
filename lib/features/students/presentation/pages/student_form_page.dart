import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/constants/app_constants.dart';
import 'package:valhalla_bjj/core/models/student.dart';
import 'package:valhalla_bjj/core/models/payment.dart';
import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/student_providers.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/providers/income_providers.dart';
import 'package:valhalla_bjj/providers/dashboard_providers.dart';
import 'package:valhalla_bjj/data/services/receipt_service.dart';

class StudentFormPage extends ConsumerStatefulWidget {
  final String? studentId;

  const StudentFormPage({super.key, this.studentId});

  @override
  ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends ConsumerState<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();

  String _tipoPlan = AppConstants.planMensual;
  String _estado = AppConstants.estadoActivo;
  String _cinturon = 'Blanco';
  DateTime _fechaInscripcion = DateTime.now();
  DateTime _fechaProximoPago = DateTime.now().add(const Duration(days: 30));
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _isEditing = true;
      _loadStudent();
    }
  }

  Future<void> _loadStudent() async {
    final student = await ref.read(studentRepositoryProvider).getById(widget.studentId!);
    if (student != null && mounted) {
      setState(() {
        _nombreController.text = student.nombre;
        _telefonoController.text = student.telefono;
        _montoController.text = student.monto.toString();
        _notasController.text = student.notas ?? '';
        _tipoPlan = student.tipoPlan;
        _estado = student.estado;
        _cinturon = student.cinturon;
        _fechaInscripcion = student.fechaInscripcion;
        _fechaProximoPago = student.fechaProximoPago;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final student = Student(
        id: widget.studentId,
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        fechaInscripcion: _fechaInscripcion,
        tipoPlan: _tipoPlan,
        monto: double.parse(_montoController.text),
        fechaProximoPago: _fechaProximoPago,
        estado: _estado,
        cinturon: _cinturon,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      if (_isEditing) {
        await ref.read(studentsProvider.notifier).updateStudent(student);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alumno actualizado'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Registrar alumno
        await ref.read(studentsProvider.notifier).addStudent(student);

        // Registrar primer pago automáticamente
        final payment = Payment(
          studentId: student.id,
          studentName: student.nombre,
          monto: student.monto,
          fechaPago: DateTime.now(),
          tipoPlan: student.tipoPlan,
          concepto: Formatters.paymentConcept(student.tipoPlan, DateTime.now()),
        );
        await ref.read(paymentRepositoryProvider).save(payment);

        // Registrar como ingreso
        final categoriaIngreso = student.tipoPlan == 'Clase suelta'
            ? 'Clases sueltas'
            : student.tipoPlan == 'Quincenal'
                ? 'Quincenas'
                : 'Mensualidades';
        final concepto = Formatters.paymentConcept(student.tipoPlan, DateTime.now());
        final income = Income(
          categoria: categoriaIngreso,
          descripcion: '${student.nombre} - $concepto (Inscripción)',
          monto: student.monto,
          fecha: DateTime.now(),
          referenceId: payment.id,
        );
        await ref.read(incomeRepositoryProvider).save(income);

        // Refrescar providers
        ref.read(incomesProvider.notifier).loadIncomes();
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(activeStudentsCountProvider);

        // Reprogramar notificaciones
        try {
          await ref.read(notificationServiceProvider).schedulePaymentReminders();
        } catch (_) {}

        if (mounted) {
          _showReceiptDialog(payment, student);
        }
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

  void _showReceiptDialog(Payment payment, Student student) {
    final receiptData = ReceiptData(
      receiptNumber: payment.id.substring(0, 8).toUpperCase(),
      studentName: student.nombre,
      studentPhone: student.telefono,
      plan: student.tipoPlan,
      amount: payment.monto,
      paymentDate: payment.fechaPago,
      nextPaymentDate: student.tipoPlan != 'Clase suelta'
          ? student.fechaProximoPago
          : null,
      concept: Formatters.paymentConcept(student.tipoPlan, payment.fechaPago),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('¡Alumno registrado!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${student.tipoPlan} - ${Formatters.currency(payment.monto)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Qué deseas hacer con el recibo de inscripción?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // volver a lista de alumnos
            },
            child: const Text('Solo cerrar'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              try {
                await ReceiptService().previewReceipt(receiptData);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Ver PDF'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              try {
                await ReceiptService().shareReceipt(receiptData);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Compartir'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
          ),
        ],
      ),
    );
  }

  /// Recalcula la fecha de próximo pago según el plan y la fecha de inscripción
  void _recalcularProximoPago() {
    switch (_tipoPlan) {
      case 'Mensual':
        _fechaProximoPago = DateTime(
          _fechaInscripcion.year,
          _fechaInscripcion.month + 1,
          _fechaInscripcion.day,
        );
        break;
      case 'Quincenal':
        _fechaProximoPago = _fechaInscripcion.add(const Duration(days: 15));
        break;
      case 'Clase suelta':
      default:
        _fechaProximoPago = _fechaInscripcion;
        break;
    }
  }

  String get _proximoPagoHint {
    switch (_tipoPlan) {
      case 'Mensual':
        return 'Calculado: 1 mes desde inscripción';
      case 'Quincenal':
        return 'Calculado: 15 días desde inscripción';
      case 'Clase suelta':
        return 'Clase suelta: pago por sesión';
      default:
        return '';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isInscripcion) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInscripcion ? _fechaInscripcion : _fechaProximoPago,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.cardDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isInscripcion) {
          _fechaInscripcion = picked;
          // Recalcular próximo pago solo si es alumno nuevo
          if (!_isEditing) {
            _recalcularProximoPago();
          }
        } else {
          _fechaProximoPago = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _montoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Alumno' : 'Nuevo Alumno'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person, color: AppColors.gold),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone, color: AppColors.gold),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Plan
            DropdownButtonFormField<String>(
              value: _tipoPlan,
              decoration: const InputDecoration(
                labelText: 'Tipo de plan',
                prefixIcon: Icon(Icons.card_membership, color: AppColors.gold),
              ),
              dropdownColor: AppColors.cardDark,
              items: AppConstants.planes.map((plan) {
                return DropdownMenuItem(value: plan, child: Text(plan));
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _tipoPlan = v;
                    _recalcularProximoPago();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Monto
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixIcon: Icon(Icons.attach_money, color: AppColors.gold),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Estado
            if (_isEditing) ...[
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.flag, color: AppColors.gold),
                ),
                dropdownColor: AppColors.cardDark,
                items: AppConstants.estadosAlumno.map((estado) {
                  return DropdownMenuItem(value: estado, child: Text(estado));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _estado = v);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Cinturón
            DropdownButtonFormField<String>(
              value: _cinturon,
              decoration: const InputDecoration(
                labelText: 'Cinturón',
                prefixIcon: Icon(Icons.sports_martial_arts, color: AppColors.gold),
              ),
              dropdownColor: AppColors.cardDark,
              items: AppConstants.cinturones.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _cinturon = v);
              },
            ),
            const SizedBox(height: 16),

            // Fecha de inscripción
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              tileColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.divider),
              ),
              leading: const Icon(Icons.calendar_today, color: AppColors.gold),
              title: const Text('Fecha de inscripción'),
              subtitle: Text(
                '${_fechaInscripcion.day}/${_fechaInscripcion.month}/${_fechaInscripcion.year}',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),

            // Próximo pago
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              tileColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.divider),
              ),
              leading: const Icon(Icons.event, color: AppColors.gold),
              title: const Text('Fecha de próximo pago'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_fechaProximoPago.day}/${_fechaProximoPago.month}/${_fechaProximoPago.year}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _proximoPagoHint,
                    style: const TextStyle(color: AppColors.gold, fontSize: 11),
                  ),
                ],
              ),
              trailing: const Icon(Icons.edit_calendar, color: AppColors.textHint, size: 18),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes, color: AppColors.gold),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isEditing ? 'Actualizar' : 'Registrar Alumno'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
