// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/category.dart';

class CategoryDao {
  CategoryDao._();
  static final CategoryDao instance = CategoryDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;
  static const String _table = 'categories';

  // ── Create ───────────────────────────────────
  Future<int> insert(Category category) async {
    final db = await _db;
    return db.insert(_table, category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // ── Read ─────────────────────────────────────
  Future<List<Category>> getAll() async {
    final db = await _db;
    final rows =
        await db.query(_table, orderBy: 'type ASC, name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Category.fromMap(rows.first);
  }

  Future<List<Category>> getByType(String type) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'type = ? OR type = ?',
        whereArgs: [type, 'both'],
        orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  // ── Update ───────────────────────────────────
  Future<int> update(Category category) async {
    final db = await _db;
    return db.update(_table, category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Delete (safe) ────────────────────────────
  Future<bool> isInUse(int id) async {
    final db = await _db;
    final tx = (await db.rawQuery(
            'SELECT COUNT(*) AS cnt FROM transactions WHERE category_id = ?',
            [id]))
        .first['cnt'] as int? ?? 0;
    if (tx > 0) return true;
    final re = (await db.rawQuery(
            'SELECT COUNT(*) AS cnt FROM recurring_expenses WHERE category_id = ?',
            [id]))
        .first['cnt'] as int? ?? 0;
    return re > 0;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Count ────────────────────────────────────
  Future<int> count() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS cnt FROM $_table');
    return (result.first['cnt'] as int?) ?? 0;
  }
}
