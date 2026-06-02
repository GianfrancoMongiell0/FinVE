import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/launcher_icon_service.dart';

const _kLogoKey = 'selected_logo_id';

enum AppLogoId { v4, v1, v6, v7, v8 }

class LogoNotifier extends AsyncNotifier<AppLogoId> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<AppLogoId> build() async {
    final raw = await _storage.read(key: _kLogoKey);
    return _fromString(raw);
  }

  Future<void> setLogo(AppLogoId id) async {
    await _storage.write(key: _kLogoKey, value: id.name);
    state = AsyncData(id);
    // Also update the real launcher icon
    await LauncherIconService.instance.setIcon(id.name);
  }

  static AppLogoId _fromString(String? raw) {
    return AppLogoId.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppLogoId.v4,
    );
  }
}

final logoProvider = AsyncNotifierProvider<LogoNotifier, AppLogoId>(
  LogoNotifier.new,
);

class LogoOption {
  final AppLogoId id;
  final String label;
  final String description;

  const LogoOption({
    required this.id,
    required this.label,
    required this.description,
  });
}

const List<LogoOption> availableLogos = [
  LogoOption(
    id: AppLogoId.v4,
    label: 'Claro + wordmark',
    description: 'Fondo claro con nombre integrado',
  ),
  LogoOption(
    id: AppLogoId.v1,
    label: 'Clásico claro',
    description: 'Fondo claro, rojo y azul',
  ),
  LogoOption(
    id: AppLogoId.v6,
    label: 'Navy suave',
    description: 'Azul marino con rojo y dorado',
  ),
  LogoOption(
    id: AppLogoId.v7,
    label: 'Navy + wordmark',
    description: 'Navy oscuro con nombre integrado',
  ),
  LogoOption(
    id: AppLogoId.v8,
    label: 'Híbrido cálido',
    description: 'Fondo cálido con rojo y dorado',
  ),
];