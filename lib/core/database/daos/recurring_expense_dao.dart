import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/recurring_expense.dart';

class RecurringExpenseDao {
  RecurringExpenseDao._();
  static final RecurringExpenseDao instance = RecurringExpenseDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;
  static const String _table = 'recurring_expenses';

  // ── Create ───────────────────────────────────
  Future<int> insert(RecurringExpense expense) async {
    final db = await _db;
    return db.insert(_table, expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // ── Read ─────────────────────────────────────
  Future<List<RecurringExpense>> getAll() async {
    final db = await _db;
    final rows =
        await db.query(_table, orderBy: 'day_of_month ASC, name ASC');
    return rows.map(RecurringExpense.fromMap).toList();
  }

  Future<RecurringExpense?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : RecurringExpense.fromMap(rows.first);
  }

  Future<List<RecurringExpense>> getDueWithin(int withinDays) async {
    final db = await _db;
    final now = DateTime.now();
    final days = <int>{};
    for (var i = 0; i <= withinDays; i++) {
      days.add(now.add(Duration(days: i)).day);
    }
    if (days.isEmpty) return [];
    final placeholders = days.map((_) => '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT * FROM $_table WHERE day_of_month IN ($placeholders) '
      'ORDER BY day_of_month ASC',
      days.toList(),
    );
    return rows.map(RecurringExpense.fromMap).toList();
  }

  Future<List<RecurringExpense>> getDueToday() async {
    final db = await _db;
    final today = DateTime.now();
    final monthPrefix =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery('''
      SELECT * FROM $_table
      WHERE day_of_month = ?
        AND (last_triggered_at IS NULL
             OR substr(last_triggered_at, 1, 7) != ?)
      ORDER BY name ASC
    ''', [today.day, monthPrefix]);
    return rows.map(RecurringExpense.fromMap).toList();
  }

  Future<List<RecurringExpense>> getByWallet(int walletId) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'wallet_id = ?',
        whereArgs: [walletId],
        orderBy: 'day_of_month ASC');
    return rows.map(RecurringExpense.fromMap).toList();
  }

  // ── Update ───────────────────────────────────
  Future<int> update(RecurringExpense expense) async {
    final db = await _db;
    return db.update(_table, expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> markTriggered(int id) async {
    final db = await _db;
    return db.update(
        _table, {'last_triggered_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Delete ───────────────────────────────────
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS cnt FROM $_table');
    return (result.first['cnt'] as int?) ?? 0;
  }
}
