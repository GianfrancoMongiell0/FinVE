import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../auth/pin_setup_screen.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await AuthService.instance.isBiometricAvailable();
    final enabled = await AuthService.instance.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    await AuthService.instance.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
    if (mounted) {
      context.showSnackBar(
        value ? 'Biométrico activado' : 'Biométrico desactivado',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _SectionHeader('PIN de acceso'),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pin_outlined,
                        color: colorScheme.primary, size: 20),
                  ),
                  title: const Text('Cambiar PIN'),
                  subtitle: const Text('Actualiza tu PIN de 4 dígitos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PinSetupScreen(isChange: true),
                    ),
                  ),
                ),
                const Divider(indent: 68),
                if (_biometricAvailable) ...[
                  _SectionHeader('Biométrico'),
                  SwitchListTile(
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.fingerprint_rounded,
                          color: colorScheme.primary, size: 22),
                    ),
                    title: const Text('Huella / Face ID'),
                    subtitle: const Text(
                        'Usar biométrico para desbloquear la app'),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                ],
                _SectionHeader('Información'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('PIN almacenado localmente'),
                  subtitle: const Text(
                      'Tu PIN se guarda de forma cifrada en el dispositivo y nunca sale de él.'),
                  isThreeLine: true,
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
