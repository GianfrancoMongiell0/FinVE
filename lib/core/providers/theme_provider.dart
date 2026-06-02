import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../shared/theme/app_colors.dart';

const _kThemeKey = 'selected_theme_id';

class ThemeNotifier extends AsyncNotifier<AppThemeId> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<AppThemeId> build() async {
    final raw = await _storage.read(key: _kThemeKey);
    return _fromString(raw);
  }

  Future<void> setTheme(AppThemeId id) async {
    await _storage.write(key: _kThemeKey, value: id.name);
    state = AsyncData(id);
  }

  static AppThemeId _fromString(String? raw) {
    return AppThemeId.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppThemeId.oceanBlue,
    );
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, AppThemeId>(
  ThemeNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeOption {
  final AppThemeId id;
  final String label;
  final String description;
  final Color primarySwatch;
  final Color accentSwatch;

  const ThemeOption({
    required this.id,
    required this.label,
    required this.description,
    required this.primarySwatch,
    required this.accentSwatch,
  });
}

const List<ThemeOption> availableThemes = [
  ThemeOption(
    id: AppThemeId.oceanBlue,
    label: 'Ocean Blue',
    description: 'Azul marino con acento verde menta',
    primarySwatch: OceanBlueColors.primary600,
    accentSwatch: OceanBlueColors.accent400,
  ),
  ThemeOption(
    id: AppThemeId.slateAmber,
    label: 'Slate & Amber',
    description: 'Gris pizarra con acento ámbar',
    primarySwatch: SlateAmberColors.primary800,
    accentSwatch: SlateAmberColors.accent200,
  ),
  ThemeOption(
    id: AppThemeId.emeraldGold,
    label: 'Emerald & Gold',
    description: 'Verde esmeralda con acento dorado',
    primarySwatch: EmeraldGoldColors.primary600,
    accentSwatch: EmeraldGoldColors.accent400,
  ),
  ThemeOption(
    id: AppThemeId.roseNight,
    label: 'Rose Night',
    description: 'Rosa oscuro elegante con negro',
    primarySwatch: RoseNightColors.primary600,
    accentSwatch: RoseNightColors.accent600,
  ),
  ThemeOption(
    id: AppThemeId.violetSunset,
    label: 'Violet Sunset',
    description: 'Púrpura vibrante con acento naranja',
    primarySwatch: VioletSunsetColors.primary600,
    accentSwatch: VioletSunsetColors.accent600,
  ),
];
