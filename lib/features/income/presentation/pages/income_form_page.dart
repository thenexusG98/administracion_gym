import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/constants/app_constants.dart';
import 'package:valhalla_bjj/core/models/income.dart';
import 'package:valhalla_bjj/providers/income_providers.dart';
import 'package:valhalla_bjj/providers/providers.dart';

class IncomeFormPage extends ConsumerStatefulWidget {
  final String? incomeId;

  const IncomeFormPage({super.key, this.incomeId});

  @override
  ConsumerState<IncomeFormPage> createState() => _IncomeFormPageState();
}

class _IncomeFormPageState extends ConsumerState<IncomeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();

  String _categoria = AppConstants.categoriasIngreso.first;
  DateTime _fecha = DateTime.now();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.incomeId != null) {
      _isEditing = true;
      _loadIncome();
    }
  }

  Future<void> _loadIncome() async {
    final income = await ref.read(incomeRepositoryProvider).getById(widget.incomeId!);
    if (income != null && mounted) {
      setState(() {
        _descripcionController.text = income.descripcion;
        _montoController.text = income.monto.toString();
        _categoria = income.categoria;
        _fecha = income.fecha;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final income = Income(
        id: widget.incomeId,
        categoria: _categoria,
        descripcion: _descripcionController.text.trim(),
        monto: double.parse(_montoController.text),
        fecha: _fecha,
      );

      if (_isEditing) {
        await ref.read(incomesProvider.notifier).updateIncome(income);
      } else {
        await ref.read(incomesProvider.notifier).addIncome(income);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Ingreso actualizado' : 'Ingreso registrado'),
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
        title: Text(_isEditing ? 'Editar Ingreso' : 'Nuevo Ingreso'),
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
              items: AppConstants.categoriasIngreso.map((cat) {
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
                    : Text(_isEditing ? 'Actualizar' : 'Registrar Ingreso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
