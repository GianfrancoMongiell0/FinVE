// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';

/// Payload wrapper used for notification action routing.
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.entityId,
  });

  final String type; // 'recurring' | 'priority' | 'daily'
  final int? entityId;

  String toJson() => jsonEncode({'type': type, 'entity_id': entityId});

  factory NotificationPayload.fromJson(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return NotificationPayload(
      type: m['type'] as String,
      entityId: m['entity_id'] as int?,
    );
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─────────────────────────────────────────────
  //  Init
  // ─────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher_v4');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundAction,
    );

    await _createChannels();
    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  Future<void> _createChannels() async {
    const daily = AndroidNotificationChannel(
      NotificationChannels.dailyReminder,
      'Recordatorio diario',
      description: 'Recordatorio para registrar gastos del día',
      importance: Importance.defaultImportance,
    );
    const recurring = AndroidNotificationChannel(
      NotificationChannels.recurringExpense,
      'Gastos recurrentes',
      description: 'Recordatorio de gastos recurrentes programados',
      importance: Importance.high,
    );
    const priority = AndroidNotificationChannel(
      NotificationChannels.priority,
      'Recordatorios de metas',
      description: 'Recordatorios personalizados para metas financieras',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(daily);
    await androidPlugin?.createNotificationChannel(recurring);
    await androidPlugin?.createNotificationChannel(priority);
  }

  // ─────────────────────────────────────────────
  //  Daily reminder
  // ─────────────────────────────────────────────
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.periodicallyShowWithDuration(
      _NotificationIds.daily,
      'FinVe — Recordatorio',
      'No olvides registrar los gastos de hoy 💰',
      const Duration(hours: 24),
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.dailyReminder,
          'Recordatorio diario',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher_v4',
        ),
      ),
      payload: const NotificationPayload(type: 'daily').toJson(),
    );
    debugPrint('[Notifications] Daily reminder scheduled at $hour:$minute');
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_NotificationIds.daily);
  }

  // ─────────────────────────────────────────────
  //  Priority reminder
  // ─────────────────────────────────────────────
  Future<void> schedulePriorityReminder({
    required int priorityId,
    required String name,
    required String amount,
  }) async {
    await _plugin.show(
      _NotificationIds.priority + priorityId,
      'Meta: $name',
      'Recuerda que tienes pendiente ahorrar $amount',
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.priority,
          'Recordatorios de metas',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher_v4',
        ),
      ),
      payload: NotificationPayload(
        type: 'priority',
        entityId: priorityId,
      ).toJson(),
    );
  }

  Future<void> cancelPriorityReminder(int priorityId) async {
    await _plugin.cancel(_NotificationIds.priority + priorityId);
  }

  // ─────────────────────────────────────────────
  //  Recurring expense reminder
  // ─────────────────────────────────────────────
  Future<void> scheduleRecurringExpenseReminder({
    required int expenseId,
    required String name,
    required String amount,
    required bool autoRegister,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.recurringExpense,
      'Gastos recurrentes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher_v4',
      // Action buttons for manual-register mode
      actions: autoRegister
          ? null
          : [
              const AndroidNotificationAction(
                'register_now',
                'Registrar ahora',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'dismiss',
                'Descartar',
                cancelNotification: true,
              ),
            ],
    );

    await _plugin.show(
      _NotificationIds.recurring + expenseId,
      autoRegister
          ? 'Gasto registrado: $name'
          : 'Recordatorio: $name vence hoy',
      autoRegister
          ? '$amount registrado automáticamente'
          : '$amount — ¿Lo registras ahora?',
      NotificationDetails(android: androidDetails),
      payload: NotificationPayload(
        type: 'recurring',
        entityId: expenseId,
      ).toJson(),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─────────────────────────────────────────────
  //  Action handlers
  // ─────────────────────────────────────────────
  static void _onAction(NotificationResponse response) {
    _handleResponse(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundAction(NotificationResponse response) {
    _handleResponse(response);
  }

  static void _handleResponse(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final payload = NotificationPayload.fromJson(response.payload!);
      if (response.actionId == 'register_now' &&
          payload.type == 'recurring' &&
          payload.entityId != null) {
        // Trigger registration — handled by RecurringService
        debugPrint(
            '[Notifications] Register now tapped for id=${payload.entityId}');
      }
    } catch (e) {
      debugPrint('[Notifications] Action handler error: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Permission request (Android 13+)
  // ─────────────────────────────────────────────
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.requestNotificationsPermission() ?? false;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }
}

class _NotificationIds {
  static const int daily = 1000;
  static const int recurring = 2000;
  static const int priority = 3000;
}
