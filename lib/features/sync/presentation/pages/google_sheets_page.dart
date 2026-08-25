import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/data/services/google_sheets_service.dart';
import 'package:valhalla_bjj/providers/providers.dart';

// ─── Provider de estado de conexión ───────────────────────────────────────────
final sheetsConnectionProvider =
    StateNotifierProvider<SheetsConnectionNotifier, SheetsConnectionState>(
  (ref) => SheetsConnectionNotifier(ref.watch(googleSheetsServiceProvider)),
);

class SheetsConnectionState {
  final bool isConnected;
  final bool isLoading;
  final String? spreadsheetId;
  final String? error;
  final DateTime? lastSync;

  const SheetsConnectionState({
    this.isConnected = false,
    this.isLoading = false,
    this.spreadsheetId,
    this.error,
    this.lastSync,
  });

  SheetsConnectionState copyWith({
    bool? isConnected,
    bool? isLoading,
    String? spreadsheetId,
    String? error,
    DateTime? lastSync,
    bool clearError = false,
  }) {
    return SheetsConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      spreadsheetId: spreadsheetId ?? this.spreadsheetId,
      error: clearError ? null : (error ?? this.error),
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class SheetsConnectionNotifier extends StateNotifier<SheetsConnectionState> {
  final GoogleSheetsService _service;

  SheetsConnectionNotifier(this._service)
      : super(SheetsConnectionState(
          isConnected: _service.isInitialized,
          spreadsheetId: _service.spreadsheetId,
        ));

  Future<void> checkConnection() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final ok = await _service.initialize();
    state = state.copyWith(
      isLoading: false,
      isConnected: ok,
      spreadsheetId: _service.spreadsheetId,
    );
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final ok = await _service.signIn();
    state = state.copyWith(
      isLoading: false,
      isConnected: ok,
      spreadsheetId: _service.spreadsheetId,
      error: ok ? null : 'No se pudo iniciar sesión con Google.',
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _service.signOut();
    state = const SheetsConnectionState();
  }

  Future<SyncResult> sync() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.syncAll();
    state = state.copyWith(
      isLoading: false,
      lastSync: result.success ? DateTime.now() : null,
      error: result.success ? null : result.message,
    );
    return result;
  }

  Future<SyncResult> fullSync() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.fullSync();
    state = state.copyWith(
      isLoading: false,
      lastSync: result.success ? DateTime.now() : null,
      error: result.success ? null : result.message,
    );
    return result;
  }
}

// ─── Página ───────────────────────────────────────────────────────────────────
class GoogleSheetsPage extends ConsumerStatefulWidget {
  const GoogleSheetsPage({super.key});

  @override
  ConsumerState<GoogleSheetsPage> createState() => _GoogleSheetsPageState();
}

class _GoogleSheetsPageState extends ConsumerState<GoogleSheetsPage> {
  @override
  void initState() {
    super.initState();
    // Verificar estado de conexión silenciosa al abrir la página
    Future.microtask(
      () => ref.read(sheetsConnectionProvider.notifier).checkConnection(),
    );
  }

  Future<void> _handleSignIn() async {
    await ref.read(sheetsConnectionProvider.notifier).signIn();
    final state = ref.read(sheetsConnectionProvider);
    if (mounted) {
      _showSnackBar(
        state.isConnected
            ? '✅ Conectado a Google Sheets'
            : state.error ?? 'Error al conectar',
        state.isConnected ? AppColors.success : AppColors.error,
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await _showConfirmDialog(
      title: 'Desconectar cuenta',
      message:
          '¿Deseas desconectar tu cuenta de Google?\n\nLos datos locales se conservan; solo se detendrá la sincronización.',
      confirmLabel: 'Desconectar',
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    await ref.read(sheetsConnectionProvider.notifier).signOut();
    if (mounted) {
      _showSnackBar('Cuenta desconectada', AppColors.textSecondary);
    }
  }

  Future<void> _handleSync() async {
    final result = await ref.read(sheetsConnectionProvider.notifier).sync();
    if (mounted) {
      _showSnackBar(
        result.success
            ? '✅ ${result.syncedCount} registros sincronizados'
            : result.message,
        result.success ? AppColors.success : AppColors.error,
      );
    }
  }

  Future<void> _handleFullSync() async {
    final confirmed = await _showConfirmDialog(
      title: 'Sincronización completa',
      message:
          '¿Reescribir TODOS los datos en Google Sheets?\n\n'
          'Esto reemplazará toda la información en la hoja de cálculo con los datos actuales del dispositivo.',
      confirmLabel: 'Sincronizar todo',
      confirmColor: AppColors.warning,
    );
    if (confirmed != true) return;

    final result =
        await ref.read(sheetsConnectionProvider.notifier).fullSync();
    if (mounted) {
      _showSnackBar(
        result.success
            ? '✅ Sincronización completa: ${result.syncedCount} registros'
            : result.message,
        result.success ? AppColors.success : AppColors.error,
      );
    }
  }

  void _copySpreadsheetId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    _showSnackBar('ID copiado al portapapeles', AppColors.info);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content:
            Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sheetsConnectionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Google Sheets'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Estado de conexión ─────────────────────────────────────────
          _ConnectionCard(
            state: state,
            onSignIn: _handleSignIn,
            onSignOut: _handleSignOut,
          ),

          const SizedBox(height: 16),

          // ── Acciones de sincronización ─────────────────────────────────
          if (state.isConnected) ...[
            _SectionTitle(title: 'SINCRONIZACIÓN'),
            const SizedBox(height: 8),

            _ActionCard(
              icon: Icons.cloud_upload,
              iconColor: AppColors.gold,
              title: 'Sincronizar cambios',
              subtitle: 'Envía solo los registros nuevos o modificados',
              trailing: state.isLoading
                  ? const _LoadingIndicator()
                  : const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: state.isLoading ? null : _handleSync,
            ),

            const SizedBox(height: 8),

            _ActionCard(
              icon: Icons.sync,
              iconColor: AppColors.warning,
              title: 'Sincronización completa',
              subtitle: 'Reescribe todos los datos en la hoja de cálculo',
              trailing: state.isLoading
                  ? const _LoadingIndicator()
                  : const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: state.isLoading ? null : _handleFullSync,
            ),

            const SizedBox(height: 24),

            // ── Info del spreadsheet ───────────────────────────────────
            _SectionTitle(title: 'HOJA DE CÁLCULO'),
            const SizedBox(height: 8),
            _SpreadsheetInfoCard(
              spreadsheetId: state.spreadsheetId,
              lastSync: state.lastSync,
              onCopyId: _copySpreadsheetId,
            ),

            const SizedBox(height: 24),

            // ── Hojas sincronizadas ────────────────────────────────────
            _SectionTitle(title: 'HOJAS SINCRONIZADAS'),
            const SizedBox(height: 8),
            _SheetsList(),

            const SizedBox(height: 24),
          ],

          // ── Cómo funciona ──────────────────────────────────────────────
          _SectionTitle(title: 'CÓMO FUNCIONA'),
          const SizedBox(height: 8),
          _HowItWorksCard(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final SheetsConnectionState state;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const _ConnectionCard({
    required this.state,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final connected = state.isConnected;
    final statusColor = connected ? AppColors.success : AppColors.textHint;
    final statusText = connected ? 'Conectado' : 'Sin conexión';
    final statusIcon = connected ? Icons.cloud_done : Icons.cloud_off;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected
              ? AppColors.success.withOpacity(0.4)
              : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Sheets',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (state.isLoading)
            const LinearProgressIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.divider,
            )
          else
            SizedBox(
              width: double.infinity,
              child: connected
                  ? OutlinedButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Desconectar cuenta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onSignIn,
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Conectar con Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 12)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SpreadsheetInfoCard extends StatelessWidget {
  final String? spreadsheetId;
  final DateTime? lastSync;
  final ValueChanged<String> onCopyId;

  const _SpreadsheetInfoCard({
    required this.spreadsheetId,
    required this.lastSync,
    required this.onCopyId,
  });

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Nombre',
            value: 'Valhalla BJJ - Administración',
          ),
          const Divider(color: AppColors.divider, height: 20),
          _InfoRow(
            label: 'ID del documento',
            value: spreadsheetId != null
                ? '${spreadsheetId!.substring(0, 12)}…'
                : 'No asignado',
            trailing: spreadsheetId != null
                ? IconButton(
                    icon: const Icon(Icons.copy,
                        size: 16, color: AppColors.textHint),
                    onPressed: () => onCopyId(spreadsheetId!),
                    tooltip: 'Copiar ID',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
          const Divider(color: AppColors.divider, height: 20),
          _InfoRow(
            label: 'Última sincronización',
            value: lastSync != null
                ? _formatDateTime(lastSync!)
                : 'Nunca en esta sesión',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SheetsList extends StatelessWidget {
  final _sheets = const [
    ('Alumnos', Icons.people, AppColors.gold),
    ('Pagos', Icons.payments, AppColors.success),
    ('Ingresos', Icons.arrow_upward, AppColors.info),
    ('Gastos', Icons.arrow_downward, AppColors.error),
    ('Inventario', Icons.inventory_2, AppColors.warning),
    ('Ventas', Icons.shopping_cart, AppColors.goldLight),
  ];

  const _SheetsList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _sheets.asMap().entries.map((entry) {
          final i = entry.key;
          final (name, icon, color) = entry.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                    ),
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                  ],
                ),
              ),
              if (i < _sheets.length - 1)
                const Divider(
                    color: AppColors.divider, height: 1, indent: 46),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HowItWorksItem(
            number: '1',
            text:
                'Conecta tu cuenta de Google con el botón "Conectar con Google".',
          ),
          SizedBox(height: 10),
          _HowItWorksItem(
            number: '2',
            text:
                'Se crea automáticamente una hoja de cálculo llamada "Valhalla BJJ - Administración" en tu Google Drive.',
          ),
          SizedBox(height: 10),
          _HowItWorksItem(
            number: '3',
            text:
                '"Sincronizar cambios" envía solo los registros nuevos o modificados desde la última sincronización.',
          ),
          SizedBox(height: 10),
          _HowItWorksItem(
            number: '4',
            text:
                '"Sincronización completa" reescribe toda la información, útil si la hoja fue modificada externamente.',
          ),
          SizedBox(height: 10),
          _HowItWorksItem(
            number: '5',
            text:
                'La app funciona sin internet. Los datos se sincronizan cuando hay conexión disponible.',
          ),
        ],
      ),
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  final String number;
  final String text;

  const _HowItWorksItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        color: AppColors.gold,
        strokeWidth: 2,
      ),
    );
  }
}
