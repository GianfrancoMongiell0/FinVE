import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────
  //  Public factory: returns [light, dark] pair
  // ─────────────────────────────────────────────
  static (ThemeData light, ThemeData dark) forId(
    AppThemeId id, {
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) {
    switch (id) {
      case AppThemeId.oceanBlue:
        return (
          _buildLight(
            dynamicLight ??
                ColorScheme.fromSeed(
                  seedColor: OceanBlueColors.seed,
                  brightness: Brightness.light,
                ),
            id,
          ),
          _buildDark(
            dynamicDark ??
                ColorScheme.fromSeed(
                  seedColor: OceanBlueColors.seed,
                  brightness: Brightness.dark,
                ),
            id,
          ),
        );
      case AppThemeId.slateAmber:
        return (
          _buildLight(
              dynamicLight ??
                  ColorScheme.fromSeed(
                      seedColor: SlateAmberColors.seed,
                      brightness: Brightness.light),
              id),
          _buildDark(
              dynamicDark ??
                  ColorScheme.fromSeed(
                      seedColor: SlateAmberColors.seed,
                      brightness: Brightness.dark),
              id),
        );
      case AppThemeId.emeraldGold:
        return (
          _buildLight(
              dynamicLight ??
                  ColorScheme.fromSeed(
                      seedColor: EmeraldGoldColors.seed,
                      brightness: Brightness.light),
              id),
          _buildDark(
              dynamicDark ??
                  ColorScheme.fromSeed(
                      seedColor: EmeraldGoldColors.seed,
                      brightness: Brightness.dark),
              id),
        );
      case AppThemeId.roseNight:
        return (
          _buildLight(
              dynamicLight ??
                  ColorScheme.fromSeed(
                      seedColor: RoseNightColors.seed,
                      brightness: Brightness.light),
              id),
          _buildDark(
              dynamicDark ??
                  ColorScheme.fromSeed(
                      seedColor: RoseNightColors.seed,
                      brightness: Brightness.dark),
              id),
        );
      case AppThemeId.violetSunset:
        return (
          _buildLight(
              dynamicLight ??
                  ColorScheme.fromSeed(
                      seedColor: VioletSunsetColors.seed,
                      brightness: Brightness.light),
              id),
          _buildDark(
              dynamicDark ??
                  ColorScheme.fromSeed(
                      seedColor: VioletSunsetColors.seed,
                      brightness: Brightness.dark),
              id),
        );
    }
  }

  // ─────────────────────────────────────────────
  //  Light theme builder
  // ─────────────────────────────────────────────
  static ThemeData _buildLight(ColorScheme scheme, AppThemeId id) {
    final colors = _colorsFor(id);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
        color: colors.cardSurface,
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary);
          }
          return IconThemeData(color: colors.onSurfaceMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelMedium.copyWith(color: colors.primary);
          }
          return AppTextStyles.labelMedium.copyWith(
            color: colors.onSurfaceMuted,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onSurfaceMuted,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.chipBackground,
        selectedColor: colors.primaryContainer,
        labelStyle: AppTextStyles.labelMedium,
        side: BorderSide(color: colors.border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onSurface,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: colors.onSurfaceMuted,
        ),
      ),
      textTheme: _buildTextTheme(colors.onSurface, colors.onSurfaceMuted),
    );
  }

  // ─────────────────────────────────────────────
  //  Dark theme builder
  // ─────────────────────────────────────────────
  static ThemeData _buildDark(ColorScheme scheme, AppThemeId id) {
    final colors = _darkColorsFor(id);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
        color: colors.cardSurface,
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary);
          }
          return IconThemeData(color: colors.onSurfaceMuted);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onSurfaceMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.chipBackground,
        selectedColor: colors.primaryContainer,
        labelStyle: AppTextStyles.labelMedium,
        side: BorderSide(color: colors.border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onSurface,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: colors.onSurfaceMuted,
        ),
      ),
      textTheme: _buildTextTheme(colors.onSurface, colors.onSurfaceMuted),
    );
  }

  // ─────────────────────────────────────────────
  //  Text theme helper
  // ─────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: primary),
      headlineLarge: AppTextStyles.headingLarge.copyWith(color: primary),
      headlineMedium: AppTextStyles.headingMedium.copyWith(color: primary),
      headlineSmall: AppTextStyles.headingSmall.copyWith(color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
    );
  }

  // ─────────────────────────────────────────────
  //  Color token helpers
  // ─────────────────────────────────────────────
  static _ThemeColors _colorsFor(AppThemeId id) {
    return switch (id) {
      AppThemeId.oceanBlue => _ThemeColors(
          primary: OceanBlueColors.primary600,
          primaryContainer: OceanBlueColors.primary50,
          accent: OceanBlueColors.accent400,
          surface: Colors.white,
          cardSurface: Colors.white,
          inputFill: OceanBlueColors.primary50,
          chipBackground: OceanBlueColors.primary50,
          onSurface: OceanBlueColors.primary900,
          onSurfaceMuted: OceanBlueColors.primary400,
          border: OceanBlueColors.primary100,
          error: OceanBlueColors.error,
        ),
      AppThemeId.slateAmber => _ThemeColors(
          primary: SlateAmberColors.primary800,
          primaryContainer: SlateAmberColors.primary50,
          accent: SlateAmberColors.accent200,
          surface: Colors.white,
          cardSurface: Colors.white,
          inputFill: SlateAmberColors.primary50,
          chipBackground: SlateAmberColors.primary50,
          onSurface: SlateAmberColors.primary900,
          onSurfaceMuted: SlateAmberColors.primary400,
          border: SlateAmberColors.primary100,
          error: SlateAmberColors.error,
        ),
      AppThemeId.emeraldGold => _ThemeColors(
          primary: EmeraldGoldColors.primary600,
          primaryContainer: EmeraldGoldColors.primary50,
          accent: EmeraldGoldColors.accent400,
          surface: Colors.white,
          cardSurface: Colors.white,
          inputFill: EmeraldGoldColors.primary50,
          chipBackground: EmeraldGoldColors.primary50,
          onSurface: EmeraldGoldColors.primary900,
          onSurfaceMuted: EmeraldGoldColors.primary400,
          border: EmeraldGoldColors.primary100,
          error: EmeraldGoldColors.error,
        ),
      AppThemeId.roseNight => _ThemeColors(
          primary: RoseNightColors.primary600,
          primaryContainer: RoseNightColors.primary50,
          accent: RoseNightColors.accent600,
          surface: Colors.white,
          cardSurface: Colors.white,
          inputFill: RoseNightColors.primary50,
          chipBackground: RoseNightColors.primary50,
          onSurface: RoseNightColors.primary900,
          onSurfaceMuted: RoseNightColors.primary400,
          border: RoseNightColors.primary100,
          error: RoseNightColors.error,
        ),
      AppThemeId.violetSunset => _ThemeColors(
          primary: VioletSunsetColors.primary600,
          primaryContainer: VioletSunsetColors.primary50,
          accent: VioletSunsetColors.accent600,
          surface: Colors.white,
          cardSurface: Colors.white,
          inputFill: VioletSunsetColors.primary50,
          chipBackground: VioletSunsetColors.primary50,
          onSurface: VioletSunsetColors.primary900,
          onSurfaceMuted: VioletSunsetColors.primary400,
          border: VioletSunsetColors.primary100,
          error: VioletSunsetColors.error,
        ),
    };
  }

  static _ThemeColors _darkColorsFor(AppThemeId id) {
    return switch (id) {
      AppThemeId.oceanBlue => _ThemeColors(
          primary: OceanBlueColors.primary200,
          primaryContainer: OceanBlueColors.primary800,
          accent: OceanBlueColors.accent200,
          surface: OceanBlueColors.primary900,
          cardSurface: OceanBlueColors.primary800,
          inputFill: OceanBlueColors.primary800,
          chipBackground: OceanBlueColors.primary800,
          onSurface: Colors.white,
          onSurfaceMuted: OceanBlueColors.primary200,
          border: OceanBlueColors.primary600,
          error: OceanBlueColors.error,
        ),
      AppThemeId.slateAmber => _ThemeColors(
          primary: SlateAmberColors.accent100,
          primaryContainer: SlateAmberColors.primary800,
          accent: SlateAmberColors.accent200,
          surface: SlateAmberColors.primary900,
          cardSurface: SlateAmberColors.primary800,
          inputFill: SlateAmberColors.primary800,
          chipBackground: SlateAmberColors.primary800,
          onSurface: Colors.white,
          onSurfaceMuted: SlateAmberColors.primary200,
          border: SlateAmberColors.primary600,
          error: SlateAmberColors.error,
        ),
      AppThemeId.emeraldGold => _ThemeColors(
          primary: EmeraldGoldColors.primary400,
          primaryContainer: EmeraldGoldColors.primary800,
          accent: EmeraldGoldColors.accent200,
          surface: EmeraldGoldColors.primary900,
          cardSurface: EmeraldGoldColors.primary800,
          inputFill: EmeraldGoldColors.primary800,
          chipBackground: EmeraldGoldColors.primary800,
          onSurface: Colors.white,
          onSurfaceMuted: EmeraldGoldColors.primary200,
          border: EmeraldGoldColors.primary600,
          error: EmeraldGoldColors.error,
        ),
      AppThemeId.roseNight => _ThemeColors(
          primary: RoseNightColors.primary200,
          primaryContainer: RoseNightColors.primary800,
          accent: RoseNightColors.accent200,
          surface: RoseNightColors.primary900,
          cardSurface: RoseNightColors.primary800,
          inputFill: RoseNightColors.primary800,
          chipBackground: RoseNightColors.primary800,
          onSurface: Colors.white,
          onSurfaceMuted: RoseNightColors.primary200,
          border: RoseNightColors.primary600,
          error: RoseNightColors.error,
        ),
      AppThemeId.violetSunset => _ThemeColors(
          primary: VioletSunsetColors.primary400,
          primaryContainer: VioletSunsetColors.primary800,
          accent: VioletSunsetColors.accent400,
          surface: VioletSunsetColors.primary900,
          cardSurface: VioletSunsetColors.primary800,
          inputFill: VioletSunsetColors.primary800,
          chipBackground: VioletSunsetColors.primary800,
          onSurface: Colors.white,
          onSurfaceMuted: VioletSunsetColors.primary200,
          border: VioletSunsetColors.primary600,
          error: VioletSunsetColors.error,
        ),
    };
  }

  // ─────────────────────────────────────────────
  //  Card gradients — 3 distinct identities per theme
  //  [0] USD card  [1] VES card  [2] Wallets card
  // ─────────────────────────────────────────────
  static List<LinearGradient> cardGradients(
      AppThemeId id, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (id) {
      AppThemeId.oceanBlue => [
          LinearGradient(
            colors: isDark
                ? [OceanBlueColors.primary800, OceanBlueColors.primary600]
                : [OceanBlueColors.primary900, OceanBlueColors.primary600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [OceanBlueColors.accent800, OceanBlueColors.accent600]
                : [OceanBlueColors.accent900, OceanBlueColors.accent600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [OceanBlueColors.primary800, OceanBlueColors.accent600]
                : [OceanBlueColors.primary800, OceanBlueColors.accent400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ],
      AppThemeId.slateAmber => [
          LinearGradient(
            colors: isDark
                ? [SlateAmberColors.primary900, SlateAmberColors.primary600]
                : [SlateAmberColors.primary900, SlateAmberColors.primary600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [SlateAmberColors.accent900, SlateAmberColors.accent600]
                : [SlateAmberColors.accent900, SlateAmberColors.accent600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [SlateAmberColors.primary800, SlateAmberColors.accent600]
                : [SlateAmberColors.primary800, SlateAmberColors.accent400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ],
      AppThemeId.emeraldGold => [
          LinearGradient(
            colors: isDark
                ? [EmeraldGoldColors.primary900, EmeraldGoldColors.primary600]
                : [EmeraldGoldColors.primary900, EmeraldGoldColors.primary600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [EmeraldGoldColors.accent900, EmeraldGoldColors.accent600]
                : [EmeraldGoldColors.accent900, EmeraldGoldColors.accent600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [EmeraldGoldColors.primary800, EmeraldGoldColors.accent600]
                : [EmeraldGoldColors.primary800, EmeraldGoldColors.accent400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ],
      AppThemeId.roseNight => [
          LinearGradient(
            colors: isDark
                ? [RoseNightColors.primary900, RoseNightColors.primary600]
                : [RoseNightColors.primary900, RoseNightColors.primary600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [RoseNightColors.accent900, RoseNightColors.accent600]
                : [RoseNightColors.accent900, RoseNightColors.accent600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [RoseNightColors.primary800, RoseNightColors.accent600]
                : [RoseNightColors.primary800, RoseNightColors.accent400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ],
      AppThemeId.violetSunset => [
          LinearGradient(
            colors: isDark
                ? [VioletSunsetColors.primary900, VioletSunsetColors.primary600]
                : [VioletSunsetColors.primary900, VioletSunsetColors.primary600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [VioletSunsetColors.accent900, VioletSunsetColors.accent600]
                : [VioletSunsetColors.accent900, VioletSunsetColors.accent600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          LinearGradient(
            colors: isDark
                ? [VioletSunsetColors.primary800, VioletSunsetColors.accent600]
                : [VioletSunsetColors.primary800, VioletSunsetColors.accent400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ],
    };
  }
}

// Internal data class — not exported
class _ThemeColors {
  final Color primary;
  final Color primaryContainer;
  final Color accent;
  final Color surface;
  final Color cardSurface;
  final Color inputFill;
  final Color chipBackground;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color border;
  final Color error;

  const _ThemeColors({
    required this.primary,
    required this.primaryContainer,
    required this.accent,
    required this.surface,
    required this.cardSurface,
    required this.inputFill,
    required this.chipBackground,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.border,
    required this.error,
  });
}