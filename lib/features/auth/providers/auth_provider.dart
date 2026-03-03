import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════
// AUTH PROVIDERS
// ═══════════════════════════════════════════

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

enum AuthState { loading, locked, authenticated, noPinSet }

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _pinKey = 'valhalla_pin';
  static const _biometricKey = 'biometric_enabled';

  AuthNotifier() : super(AuthState.loading) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final pin = await _storage.read(key: _pinKey);
    if (pin == null) {
      state = AuthState.noPinSet;
    } else {
      state = AuthState.locked;
    }
  }

  Future<bool> setPin(String pin) async {
    try {
      await _storage.write(key: _pinKey, value: pin);
      state = AuthState.authenticated;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _storage.read(key: _pinKey);
      if (storedPin == pin) {
        state = AuthState.authenticated;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) return false;

      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool(_biometricKey) ?? false;
      if (!biometricEnabled) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Autenticarse para acceder a Valhalla BJJ',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        state = AuthState.authenticated;
      }
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  Future<void> enableBiometrics(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enable);
  }

  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    state = AuthState.locked;
  }

  Future<void> changePin(String newPin) async {
    await _storage.write(key: _pinKey, value: newPin);
  }
}
