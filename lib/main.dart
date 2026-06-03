// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'core/services/recurring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Warm up database (creates schema + seeds categories on first run)
  await DatabaseHelper.instance.database;

  await initializeDateFormatting('es', null);

  // 2. Initialize notifications
  await NotificationService.instance.init();

  // 3. Check recurring expenses due today
  await RecurringService.instance.checkDueExpenses();

  runApp(
    const ProviderScope(
      child: FinVeApp(),
    ),
  );
}
