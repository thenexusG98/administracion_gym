import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/constants/app_constants.dart';
import 'package:valhalla_bjj/core/models/expense.dart';
import 'package:valhalla_bjj/providers/expense_providers.dart';
import 'package:valhalla_bjj/providers/providers.dart';

class ExpenseFormPage extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseFormPage({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();

  String _categoria = AppConstants.categoriasGasto.first;
  DateTime _fecha = DateTime.now();
  bool _esRecurrente = false;
  int? _diaRecurrente;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _isEditing = true;
      _loadExpense();
    }
  }

  Future<void> _loadExpense() async {
    final expense = await ref.read(expenseRepositoryProvider).getById(widget.expenseId!);
    if (expense != null && mounted) {
      setState(() {
        _descripcionController.text = expense.descripcion;
        _montoController.text = expense.monto.toString();
        _categoria = expense.categoria;
        _fecha = expense.fecha;
        _esRecurrente = expense.esRecurrente;
        _diaRecurrente = expense.diaRecurrente;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final expense = Expense(
        id: widget.expenseId,
        categoria: _categoria,
        descripcion: _descripcionController.text.trim(),
        monto: double.parse(_montoController.text),
        fecha: _fecha,
        esRecurrente: _esRecurrente,
        diaRecurrente: _esRecurrente ? _diaRecurrente : null,
      );

      if (_isEditing) {
        await ref.read(expensesProvider.notifier).updateExpense(expense);
      } else {
        await ref.read(expensesProvider.notifier).addExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Gasto actualizado' : 'Gasto registrado'),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
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
    if (picked != null) setState(() => _fecha = picked);
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Gasto' : 'Nuevo Gasto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category, color: AppColors.gold),
              ),
              dropdownColor: AppColors.cardDark,
              items: AppConstants.categoriasGasto.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _categoria = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description, color: AppColors.gold),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
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
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              tileColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.divider),
              ),
              leading: const Icon(Icons.calendar_today, color: AppColors.gold),
              title: const Text('Fecha'),
              subtitle: Text(
                '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),

            // Recurrente
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              tileColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.divider),
              ),
              title: const Text('Gasto recurrente'),
              subtitle: const Text('Se repite cada mes'),
              secondary: const Icon(Icons.repeat, color: AppColors.gold),
              value: _esRecurrente,
              activeColor: AppColors.gold,
              onChanged: (v) => setState(() => _esRecurrente = v),
            ),

            if (_esRecurrente) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _diaRecurrente?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Día del mes',
                  prefixIcon: Icon(Icons.event, color: AppColors.gold),
                  hintText: 'Ej: 1, 15, 28',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => _diaRecurrente = int.tryParse(v),
                validator: (v) {
                  if (!_esRecurrente) return null;
                  final day = int.tryParse(v ?? '');
                  if (day == null || day < 1 || day > 31) return 'Día inválido (1-31)';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Actualizar' : 'Registrar Gasto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
