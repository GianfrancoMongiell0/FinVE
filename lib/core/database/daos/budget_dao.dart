import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/budget.dart';

class BudgetDao {
  BudgetDao._();
  static final BudgetDao instance = BudgetDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;
  static const _table = 'budgets';

  Future<int> insert(Budget b) async {
    final db = await _db;
    return db.insert(_table, b.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(Budget b) async {
    final db = await _db;
    return db.update(_table, b.toMap(),
        where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Budget>> getForMonth(int month, int year) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> getForCategory(
      int categoryId, int month, int year) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'category_id = ? AND month = ? AND year = ?',
      whereArgs: [categoryId, month, year],
      limit: 1,
    );
    return rows.isEmpty ? null : Budget.fromMap(rows.first);
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(_table);
  }
}
