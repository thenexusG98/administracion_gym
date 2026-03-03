import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/data/services/google_sheets_service.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/students_page.dart';
import 'package:valhalla_bjj/features/income/presentation/pages/income_page.dart';
import 'package:valhalla_bjj/features/expenses/presentation/pages/expenses_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/inventory_page.dart';

class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key});

  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    StudentsPage(),
    IncomePage(),
    ExpensesPage(),
    InventoryPage(),
  ];

  static const _titles = [
    'Dashboard',
    'Alumnos',
    'Ingresos',
    'Gastos',
    'Inventario',
  ];

  Future<void> _syncToSheets() async {
    final syncStatus = ref.read(syncStatusProvider.notifier);
    syncStatus.state = SyncStatus.syncing;

    try {
      final sheetsService = ref.read(googleSheetsServiceProvider);
      final result = await sheetsService.syncAll();

      if (mounted) {
        syncStatus.state = SyncStatus.success;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Sincronizado: ${result.syncedCount} registros'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        syncStatus.state = SyncStatus.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    // Reset status after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        syncStatus.state = SyncStatus.idle;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🐚 ShellPage build, tab=$_currentIndex');
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.1),
            ),
            child: const Center(
              child: Text('⚔️', style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
        actions: [
          // Sync button
          IconButton(
            onPressed: syncStatus == SyncStatus.syncing ? null : _syncToSheets,
            icon: syncStatus == SyncStatus.syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    syncStatus == SyncStatus.success
                        ? Icons.cloud_done
                        : syncStatus == SyncStatus.error
                            ? Icons.cloud_off
                            : Icons.cloud_upload,
                    color: syncStatus == SyncStatus.success
                        ? AppColors.success
                        : syncStatus == SyncStatus.error
                            ? AppColors.error
                            : AppColors.gold,
                  ),
            tooltip: 'Sincronizar con Google Sheets',
          ),
          // Settings / more
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) async {
              switch (value) {
                case 'full_sync':
                  _showFullSyncDialog();
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'full_sync',
                child: ListTile(
                  leading: Icon(Icons.sync, color: AppColors.warning),
                  title: Text('Sincronización completa'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.info),
                  title: Text('Acerca de'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.textHint,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Alumnos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.arrow_upward),
              activeIcon: Icon(Icons.arrow_upward_rounded),
              label: 'Ingresos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.arrow_downward),
              activeIcon: Icon(Icons.arrow_downward_rounded),
              label: 'Gastos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
          ],
        ),
      ),
    );
  }

  void _showFullSyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sincronización Completa'),
        content: const Text(
          '¿Deseas reescribir TODOS los datos en Google Sheets?\n\n'
          'Esto reemplazará toda la información en la hoja de cálculo '
          'con los datos actuales del dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final syncStatus = ref.read(syncStatusProvider.notifier);
              syncStatus.state = SyncStatus.syncing;
              try {
                final sheetsService = ref.read(googleSheetsServiceProvider);
                await sheetsService.fullSync();
                if (mounted) {
                  syncStatus.state = SyncStatus.success;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Sincronización completa exitosa'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  syncStatus.state = SyncStatus.error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Sincronizar Todo'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Text('⚔️ ', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Valhalla BJJ'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistema de Administración',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Versión 1.0.0'),
            SizedBox(height: 4),
            Text(
              'Control total financiero y operativo del gimnasio.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              '• Gestión de alumnos y membresías\n'
              '• Control de ingresos y gastos\n'
              '• Inventario de equipo y ventas\n'
              '• Reportes financieros automáticos\n'
              '• Sincronización con Google Sheets\n'
              '• Funciona sin internet',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
