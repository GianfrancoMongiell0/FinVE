import 'package:flutter/foundation.dart';
import '../database/daos/recurring_expense_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../database/daos/wallet_dao.dart';
import '../models/recurring_expense.dart';
import '../models/transaction.dart' as app_models;
import '../utils/constants.dart';
import 'notification_service.dart';

class RecurringService {
  RecurringService._();
  static final RecurringService instance = RecurringService._();

  final _recurringDao = RecurringExpenseDao.instance;
  final _txDao = TransactionDao.instance;
  final _walletDao = WalletDao.instance;

  // ─────────────────────────────────────────────
  //  Main entry — call on app launch and via WorkManager
  // ─────────────────────────────────────────────
  Future<void> checkDueExpenses() async {
    debugPrint('[RecurringService] Checking due expenses…');
    try {
      final dueToday = await _recurringDao.getDueToday();
      for (final expense in dueToday) {
        await triggerExpense(expense);
      }
      debugPrint(
          '[RecurringService] Processed ${dueToday.length} due expenses');
    } catch (e) {
      debugPrint('[RecurringService] Error: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Trigger a single recurring expense
  // ─────────────────────────────────────────────
  Future<void> triggerExpense(RecurringExpense expense) async {
    if (expense.autoRegister) {
      await _autoRegister(expense);
    } else {
      await _sendReminder(expense);
    }
    await _recurringDao.markTriggered(expense.id!);
  }

  Future<void> _autoRegister(RecurringExpense expense) async {
    final transaction = app_models.Transaction(
      walletId: expense.walletId,
      amount: expense.amount,
      type: TransactionType.expense,
      categoryId: expense.categoryId,
      paymentMethod: expense.paymentMethod,
      note: 'Auto-registrado: ${expense.name}',
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _txDao.insert(transaction);
    await _walletDao.adjustBalance(expense.walletId, -expense.amount);

    // Notify user about auto-registration
    final formattedAmount =
        '${expense.amount.toStringAsFixed(2)} ${expense.currencyCode}';
    await NotificationService.instance.scheduleRecurringExpenseReminder(
      expenseId: expense.id!,
      name: expense.name,
      amount: formattedAmount,
      autoRegister: true,
    );

    debugPrint(
        '[RecurringService] Auto-registered: ${expense.name}');
  }

  Future<void> _sendReminder(RecurringExpense expense) async {
    final formattedAmount =
        '${expense.amount.toStringAsFixed(2)} ${expense.currencyCode}';
    await NotificationService.instance.scheduleRecurringExpenseReminder(
      expenseId: expense.id!,
      name: expense.name,
      amount: formattedAmount,
      autoRegister: false,
    );
    debugPrint(
        '[RecurringService] Reminder sent: ${expense.name}');
  }

  // ─────────────────────────────────────────────
  //  Manual register from notification action
  // ─────────────────────────────────────────────
  Future<bool> registerFromNotification(int expenseId) async {
    try {
      final expense = await _recurringDao.getById(expenseId);
      if (expense == null) return false;

      final transaction = app_models.Transaction(
        walletId: expense.walletId,
        amount: expense.amount,
        type: TransactionType.expense,
        categoryId: expense.categoryId,
        paymentMethod: expense.paymentMethod,
        note: 'Registrado desde notificación: ${expense.name}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _txDao.insert(transaction);
      await _walletDao.adjustBalance(expense.walletId, -expense.amount);
      await _recurringDao.markTriggered(expenseId);

      return true;
    } catch (e) {
      debugPrint('[RecurringService] registerFromNotification error: $e');
      return false;
    }
  }
}

// ─────────────────────────────────────────────
//  WorkManager background task callback
//  Register this in main() with:
//  Workmanager().registerPeriodicTask(...)
// ─────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> recurringServiceBackgroundTask() async {
  debugPrint('[WorkManager] Running recurring check…');
  await RecurringService.instance.checkDueExpenses();
}
