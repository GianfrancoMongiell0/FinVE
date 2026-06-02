import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/theme/app_text_styles.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _storage = FlutterSecureStorage();

  bool _dailyEnabled = false;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 20, minute: 0);
  bool _notificationsGranted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final granted =
        await NotificationService.instance.areNotificationsEnabled();
    final enabled =
        await _storage.read(key: StorageKeys.dailyReminderEnabled);
    final timeRaw =
        await _storage.read(key: StorageKeys.dailyReminderTime);

    TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);
    if (timeRaw != null) {
      final parts = timeRaw.split(':');
      if (parts.length == 2) {
        time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 20,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    if (mounted) {
      setState(() {
        _notificationsGranted = granted;
        _dailyEnabled = enabled == 'true';
        _dailyTime = time;
        _loading = false;
      });
    }
  }

  Future<void> _toggleDaily(bool value) async {
    if (value && !_notificationsGranted) {
      final granted =
          await NotificationService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          context.showSnackBar(
              'Habilita las notificaciones en Ajustes del sistema',
              isError: true);
        }
        return;
      }
      setState(() => _notificationsGranted = true);
    }

    await _storage.write(
        key: StorageKeys.dailyReminderEnabled, value: value.toString());
    setState(() => _dailyEnabled = value);

    if (value) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _dailyTime.hour,
        minute: _dailyTime.minute,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyTime,
    );
    if (picked != null) {
      setState(() => _dailyTime = picked);
      await _storage.write(
        key: StorageKeys.dailyReminderTime,
        value: '${picked.hour}:${picked.minute}',
      );
      if (_dailyEnabled) {
        await NotificationService.instance.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Permission status ────────────
                if (!_notificationsGranted)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            color: colorScheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Las notificaciones están desactivadas. '
                            'Actívalas en los ajustes del sistema.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: colorScheme.error),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final granted = await NotificationService
                                .instance
                                .requestPermission();
                            setState(
                                () => _notificationsGranted = granted);
                          },
                          child: const Text('Activar'),
                        ),
                      ],
                    ),
                  ),

                _Section('Recordatorio diario'),

                SwitchListTile(
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_outlined,
                        color: colorScheme.primary, size: 20),
                  ),
                  title: const Text('Recordatorio diario'),
                  subtitle: const Text(
                      'Recibe un recordatorio para registrar tus gastos'),
                  value: _dailyEnabled,
                  onChanged: _toggleDaily,
                ),

                if (_dailyEnabled)
                  ListTile(
                    leading: const SizedBox(width: 40),
                    title: const Text('Hora del recordatorio'),
                    subtitle: Text(_dailyTime.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickTime,
                  ),

                _Section('Gastos recurrentes'),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_repeat_rounded,
                        color: colorScheme.primary, size: 20),
                  ),
                  title: const Text('Recordatorios automáticos'),
                  subtitle: const Text(
                      'Los gastos recurrentes envían notificaciones en su fecha programada. '
                      'Configura cada gasto por separado.'),
                  isThreeLine: true,
                ),

                _Section('Metas financieras'),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flag_outlined,
                        color: colorScheme.primary, size: 20),
                  ),
                  title: const Text('Recordatorios de metas'),
                  subtitle: const Text(
                      'Próximamente: recordatorios personalizados por meta'),
                  enabled: false,
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
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
