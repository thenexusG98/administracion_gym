import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/core/models/student.dart';
import 'package:valhalla_bjj/core/utils/formatters.dart';
import 'package:valhalla_bjj/providers/student_providers.dart';
import 'package:valhalla_bjj/providers/dashboard_providers.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/student_form_page.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/student_detail_page.dart';
import 'package:valhalla_bjj/shared/widgets/common_widgets.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  String _searchQuery = '';
  String _filterEstado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Alumnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _navigateToForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar alumno...',
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Todos', 'Activo', 'Vencido', 'Suspendido'].map((estado) {
                final isSelected = _filterEstado == estado;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(estado),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterEstado = estado),
                    selectedColor: AppColors.gold,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.black : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: studentsAsync.when(
              loading: () => const LoadingIndicator(message: 'Cargando alumnos...'),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                var filtered = students;

                if (_filterEstado != 'Todos') {
                  filtered = filtered.where((s) => s.estado == _filterEstado).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where((s) =>
                          s.nombre.toLowerCase().contains(q) ||
                          s.telefono.contains(q))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: 'Sin alumnos',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'No se encontraron resultados'
                        : 'Agrega tu primer alumno',
                    buttonText: _searchQuery.isEmpty ? 'Agregar alumno' : null,
                    onButtonPressed:
                        _searchQuery.isEmpty ? () => _navigateToForm(context) : null,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: () => ref.read(studentsProvider.notifier).loadStudents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _StudentListTile(
                        student: filtered[index],
                        onTap: () => _navigateToDetail(context, filtered[index].id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Future<void> _navigateToForm(BuildContext context, [String? studentId]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormPage(studentId: studentId),
      ),
    );
    // Al regresar, refrescar datos
    if (mounted) {
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(expiringSoonStudentsProvider);
    }
  }

  Future<void> _navigateToDetail(BuildContext context, String studentId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailPage(studentId: studentId),
      ),
    );
    // Al regresar del detalle, refrescar datos por si se registró un pago
    if (mounted) {
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(expiringSoonStudentsProvider);
    }
  }
}

class _StudentListTile extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentListTile({required this.student, required this.onTap});

  Color get _statusColor {
    switch (student.estado) {
      case 'Activo':
        return student.isExpiringSoon ? AppColors.warning : AppColors.success;
      case 'Vencido':
        return AppColors.error;
      case 'Suspendido':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  Color _paymentStatusColor(Student s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(s.fechaProximoPago.year, s.fechaProximoPago.month, s.fechaProximoPago.day);
    final diff = target.difference(today).inDays;
    if (s.tipoPlan == 'Clase suelta') {
      return diff >= 0 ? AppColors.success : AppColors.textHint;
    }
    if (diff < 0) return AppColors.error;
    if (diff <= 3) return AppColors.warning;
    return AppColors.success;
  }

  String get _beltEmoji {
    switch (student.cinturon) {
      case 'Blanco':
        return '⬜';
      case 'Azul':
        return '🟦';
      case 'Púrpura':
        return '🟪';
      case 'Café':
        return '🟫';
      case 'Negro':
        return '⬛';
      default:
        return '⬜';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValhallaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar con cinturón
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                _beltEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.nombre,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      student.telefono,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        student.estado,
                        style: TextStyle(
                          fontSize: 11,
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Monto y fecha
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(student.monto),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.paymentStatus(student),
                style: TextStyle(
                  fontSize: 11,
                  color: _paymentStatusColor(student),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
