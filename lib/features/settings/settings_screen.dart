// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/theme_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../core/providers/logo_provider.dart';
import '../../shared/widgets/finve_logo.dart';
import 'screens/category_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/rate_settings_screen.dart';
import 'screens/recurring_settings_screen.dart';
import 'screens/security_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    final currentTheme = themeAsync.valueOrNull ?? AppThemeId.oceanBlue;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────
          _SectionHeader('Apariencia'),
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconBg: colorScheme.primaryContainer,
            iconColor: colorScheme.primary,
            title: 'Tema de colores',
            subtitle: currentTheme == AppThemeId.oceanBlue
                ? 'Ocean Blue'
                : 'Slate & Amber',
            onTap: () => _showThemePicker(context, ref, currentTheme),
          ),

          const _LogoPickerTile(),

          // ── Security ────────────────────────
          _SectionHeader('Seguridad'),

          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            iconBg: const Color(0xFFE6F1FB),
            iconColor: const Color(0xFF185FA5),
            title: 'PIN y biométrico',
            subtitle: 'Cambia tu PIN o activa la huella',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
            ),
          ),

          // ── Rates ───────────────────────────
          _SectionHeader('Tasas de cambio'),

          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            iconBg: const Color(0xFFE1F5EE),
            iconColor: const Color(0xFF1D9E75),
            title: 'Tasas BCV y crypto',
            subtitle: 'Ver tasas actuales y establecer valores manuales',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RateSettingsScreen()),
            ),
          ),

          // ── Categories ──────────────────────
          _SectionHeader('Organización'),

          _SettingsTile(
            icon: Icons.category_outlined,
            iconBg: const Color(0xFFFAEEDA),
            iconColor: const Color(0xFF854F0B),
            title: 'Categorías',
            subtitle: 'Agrega, edita o elimina categorías',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategorySettingsScreen()),
            ),
          ),

          _SettingsTile(
            icon: Icons.event_repeat_rounded,
            iconBg: const Color(0xFFEEEDFE),
            iconColor: const Color(0xFF534AB7),
            title: 'Gastos recurrentes',
            subtitle: 'Programa gastos fijos con recordatorios automáticos',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const RecurringSettingsScreen()),
            ),
          ),

          // ── Notifications ───────────────────
          _SettingsTile(
            icon: Icons.pie_chart_outline_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
            title: 'Presupuesto mensual',
            subtitle: 'Define límites de gasto por categoría',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/budget'),
          ),

          _SectionHeader('Notificaciones'),

          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconBg: const Color(0xFFFFE5E5),
            iconColor: const Color(0xFFD32F2F),
            title: 'Recordatorios',
            subtitle: 'Configura el recordatorio diario',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            ),
          ),

          // ── About ───────────────────────────
          _SectionHeader('Acerca de'),

          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconBg: colorScheme.surfaceContainerHighest,
            iconColor: colorScheme.onSurfaceVariant,
            title: 'FinVe',
            subtitle: 'Versión 1.0.0 · Hecho con ❤️ en Venezuela',
          ),

          _SettingsTile(
            icon: Icons.storage_outlined,
            iconBg: colorScheme.surfaceContainerHighest,
            iconColor: colorScheme.onSurfaceVariant,
            title: 'Almacenamiento',
            subtitle: 'Todos los datos se guardan localmente en tu dispositivo',
          ),

          // ── Zona de peligro ──────────────────
          _SectionHeader('Zona de peligro'),

          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            iconBg: colorScheme.errorContainer.withOpacity(0.5),
            iconColor: colorScheme.error,
            title: 'Borrar todos los datos',
            subtitle:
                'Elimina billeteras, transacciones, metas y categorías personalizadas',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmReset(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.delete_forever_outlined,
            size: 36, color: Theme.of(context).colorScheme.error),
        title: const Text('¿Borrar todos los datos?'),
        content: const Text(
          'Se eliminarán todas las billeteras, transacciones, metas y gastos recurrentes.\n\nEsta acción NO se puede deshacer.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await DatabaseHelper.instance.resetForTesting();
      if (context.mounted) {
        context.showSnackBar('Todos los datos han sido eliminados');
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (_) => false);
      }
    }
  }

  void _showThemePicker(
      BuildContext context, WidgetRef ref, AppThemeId current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ThemePicker(currentTheme: current, ref: ref),
    );
  }
}

// ── Theme picker sheet ────────────────────────
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.currentTheme, required this.ref});
  final AppThemeId currentTheme;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Elige un tema',
              style: AppTextStyles.headingSmall
                  .copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          ...availableThemes.map((theme) {
            final selected = currentTheme == theme.id;
            return GestureDetector(
              onTap: () {
                ref.read(themeProvider.notifier).setTheme(theme.id);
                Navigator.of(context).pop();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primaryContainer.withOpacity(0.4)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? Border.all(color: colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.primarySwatch,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.accentSwatch,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(theme.label,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: colorScheme.onSurface)),
                          Text(theme.description,
                              style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_rounded, color: colorScheme.primary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: AppTextStyles.labelLarge
            .copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style:
              AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface)),
      subtitle: Text(subtitle,
          style: AppTextStyles.caption
              .copyWith(color: colorScheme.onSurfaceVariant)),
      trailing: trailing,
      onTap: onTap,
      enabled: onTap != null,
    );
  }
} // ── Logo picker tile ─────────────────────────────────

class _LogoPickerTile extends ConsumerWidget {
  const _LogoPickerTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoAsync = ref.watch(logoProvider);
    final currentLogo = logoAsync.valueOrNull ?? AppLogoId.v4;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.app_shortcut_outlined,
            color: colorScheme.primary, size: 22),
      ),
      title: Text('Ícono de la app',
          style:
              AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface)),
      subtitle: Text('Personaliza el ícono del launcher',
          style: AppTextStyles.caption
              .copyWith(color: colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLogoPicker(context, ref, currentLogo),
    );
  }

  void _showLogoPicker(BuildContext context, WidgetRef ref, AppLogoId current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ícono de la app',
                style: AppTextStyles.headingSmall
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppLogoId.values.map((logoId) {
                final selected = current == logoId;
                final colorScheme = Theme.of(context).colorScheme;
                return GestureDetector(
                  onTap: () {
                    ref.read(logoProvider.notifier).setLogo(logoId);
                    Navigator.of(context).pop();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: selected
                              ? Border.all(color: colorScheme.primary, width: 2)
                              : Border.all(color: Colors.transparent, width: 2),
                        ),
                        child: FinveLogo(logoId: logoId, size: 64),
                      ),
                      const SizedBox(height: 6),
                      if (selected)
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: colorScheme.primary)
                      else
                        const SizedBox(height: 16),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
