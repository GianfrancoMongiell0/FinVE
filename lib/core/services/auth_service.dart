import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/constants.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ─────────────────────────────────────────────
  //  PIN management
  // ─────────────────────────────────────────────

  /// Returns true if a PIN has been set by the user.
  Future<bool> isPinSet() async {
    final pin = await _storage.read(key: StorageKeys.pin);
    return pin != null && pin.isNotEmpty;
  }

  /// Saves a new PIN. Overwrites any existing PIN.
  Future<void> savePin(String pin) async {
    assert(pin.length == 4 && int.tryParse(pin) != null,
        'PIN must be exactly 4 digits');
    await _storage.write(key: StorageKeys.pin, value: pin);
  }

  /// Returns true if [pin] matches the stored PIN.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: StorageKeys.pin);
    return stored != null && stored == pin;
  }

  /// Removes the stored PIN and disables biometrics.
  Future<void> clearPin() async {
    await _storage.delete(key: StorageKeys.pin);
    await _storage.delete(key: StorageKeys.biometricEnabled);
  }

  // ─────────────────────────────────────────────
  //  Biometric management
  // ─────────────────────────────────────────────

  /// Returns true if the device supports biometric authentication
  /// and has at least one enrolled biometric.
  Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // canCheckBiometrics = hardware exists
      // getAvailableBiometrics = at least one enrolled
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('[AuthService] Biometric check error: $e');
      // On some Xiaomi devices the check throws even when biometrics work.
      // Fall back to trusting the user's setting.
      return true;
    }
  }

  /// Returns true if the user has opted in to biometric auth.
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: StorageKeys.biometricEnabled);
    return value == 'true';
  }

  /// Enables or disables biometric auth preference.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: StorageKeys.biometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Prompts the user with a biometric (fingerprint/face) dialog.
  /// Returns true on success, false if cancelled or failed.
  Future<bool> authenticateWithBiometric() async {
  try {
    final authenticated = await _localAuth.authenticate(
      localizedReason: 'Confirma tu identidad para acceder a FinVe',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
    return authenticated;
  } on PlatformException {
    return false;
  }
}

  // ─────────────────────────────────────────────
  //  Combined auth flow
  // ─────────────────────────────────────────────

  /// Attempts biometric first (if available + enabled), falls back to PIN.
  /// Returns [AuthResult] describing what happened.
  Future<AuthResult> attemptBiometric() async {
    final biometricAvailable = await isBiometricAvailable();
    final biometricEnabled = await isBiometricEnabled();

    if (!biometricAvailable || !biometricEnabled) {
      return AuthResult.biometricUnavailable;
    }

    final success = await authenticateWithBiometric();
    return success ? AuthResult.success : AuthResult.biometricFailed;
  }
}

enum AuthResult {
  success,
  biometricUnavailable,
  biometricFailed,
  pinIncorrect,
}