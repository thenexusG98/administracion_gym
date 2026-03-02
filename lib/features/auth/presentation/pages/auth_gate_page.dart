import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valhalla_bjj/core/theme/app_colors.dart';
import 'package:valhalla_bjj/features/auth/providers/auth_provider.dart';
import 'package:valhalla_bjj/features/shell/presentation/pages/shell_page.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _errorMessage;
  bool _isSettingPin = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final auth = ref.read(authProvider.notifier);
    final success = await auth.authenticateWithBiometrics();
    if (success && mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ShellPage()),
    );
  }

  Future<void> _verifyPin() async {
    final auth = ref.read(authProvider.notifier);
    final success = await auth.verifyPin(_pinController.text);
    if (success) {
      _navigateToHome();
    } else {
      setState(() => _errorMessage = 'PIN incorrecto');
    }
  }

  Future<void> _setNewPin() async {
    if (_pinController.text.length != 4) {
      setState(() => _errorMessage = 'El PIN debe ser de 4 dígitos');
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      setState(() => _errorMessage = 'Los PINs no coinciden');
      return;
    }
    final auth = ref.read(authProvider.notifier);
    await auth.setPin(_pinController.text);
    _navigateToHome();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkGrey, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_martial_arts,
                      size: 64,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'VALHALLA BJJ',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          letterSpacing: 4,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Administración',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 48),

                  if (authState == AuthState.noPinSet) ...[
                    Text(
                      _isSettingPin ? 'Configura tu PIN de acceso' : 'Bienvenido',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (!_isSettingPin) ...[
                      Text(
                        'Configura un PIN para proteger tu información',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => setState(() => _isSettingPin = true),
                        child: const Text('Configurar PIN'),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      _buildPinField(_pinController, 'Nuevo PIN'),
                      const SizedBox(height: 16),
                      _buildPinField(_confirmPinController, 'Confirmar PIN'),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _setNewPin,
                        child: const Text('Guardar PIN'),
                      ),
                    ],
                  ] else if (authState == AuthState.locked) ...[
                    Text(
                      'Ingresa tu PIN',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    _buildPinField(_pinController, 'PIN'),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _verifyPin,
                      child: const Text('Desbloquear'),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _tryBiometric,
                      icon: const Icon(Icons.fingerprint, color: AppColors.gold),
                      label: const Text(
                        'Usar biometría',
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinField(TextEditingController controller, String label) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          letterSpacing: 16,
          color: AppColors.gold,
        ),
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
        ),
        onChanged: (_) => setState(() => _errorMessage = null),
      ),
    );
  }
}
