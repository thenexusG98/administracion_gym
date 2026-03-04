import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/data/services/google_sheets_service.dart';
import 'package:valhalla_bjj/providers/providers.dart';
import 'package:valhalla_bjj/providers/dashboard_providers.dart';
import 'package:valhalla_bjj/providers/student_providers.dart';
import 'package:valhalla_bjj/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/students_page.dart';
import 'package:valhalla_bjj/features/income/presentation/pages/income_page.dart';
import 'package:valhalla_bjj/features/expenses/presentation/pages/expenses_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/inventory_page.dart';
import 'package:valhalla_bjj/features/timer/presentation/pages/fight_timer_page.dart';
import 'package:valhalla_bjj/features/receipts/presentation/pages/receipts_page.dart';

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
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_valhalla_192.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
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
          onTap: (index) {
            // Si regresa al dashboard, refrescar datos automáticamente
            if (index == 0 && _currentIndex != 0) {
              ref.invalidate(dashboardDataProvider);
              ref.invalidate(expiringSoonStudentsProvider);
              ref.invalidate(activeStudentsCountProvider);
            }
            setState(() => _currentIndex = index);
          },
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header del drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo_valhalla_192.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Valhalla BJJ',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Sistema de Administración',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Sección: Herramientas
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    'HERRAMIENTAS',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Timer de combate
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer, color: AppColors.red, size: 22),
              ),
              title: const Text(
                'Timer de Combate',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Rondas, tiempo y descanso',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FightTimerPage()),
                );
              },
            ),

            const Divider(color: AppColors.divider, height: 1, indent: 20, endIndent: 20),

            // Recibos de pago
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.gold, size: 22),
              ),
              title: const Text(
                'Recibos de Pago',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Generar y compartir recibos PDF',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiptsPage()),
                );
              },
            ),

            const Divider(color: AppColors.divider, height: 1, indent: 20, endIndent: 20),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v1.0.0 • Valhalla BJJ',
                style: TextStyle(
                  color: AppColors.textHint.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
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
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo_valhalla_192.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Valhalla BJJ'),
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
