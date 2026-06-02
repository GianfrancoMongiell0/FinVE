import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/priority.dart';

class PriorityDao {
  PriorityDao._();
  static final PriorityDao instance = PriorityDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;
  static const String _table = 'priorities';

  static const String _orderByLevel = '''
    CASE priority_level
      WHEN 'high'   THEN 1
      WHEN 'medium' THEN 2
      WHEN 'low'    THEN 3
    END ASC, created_at ASC
  ''';

  // ── Create ───────────────────────────────────
  Future<int> insert(Priority priority) async {
    final db = await _db;
    return db.insert(_table, priority.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // ── Read ─────────────────────────────────────
  Future<List<Priority>> getAll() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: _orderByLevel);
    return rows.map(Priority.fromMap).toList();
  }

  Future<List<Priority>> getPending() async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'is_completed = 0', orderBy: _orderByLevel);
    return rows.map(Priority.fromMap).toList();
  }

  Future<List<Priority>> getCompleted() async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'is_completed = 1', orderBy: 'created_at DESC');
    return rows.map(Priority.fromMap).toList();
  }

  Future<Priority?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Priority.fromMap(rows.first);
  }

  // ── Update ───────────────────────────────────
  Future<int> update(Priority priority) async {
    final db = await _db;
    return db.update(_table, priority.toMap(),
        where: 'id = ?',
        whereArgs: [priority.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> markCompleted(int id, {bool completed = true}) async {
    final db = await _db;
    return db.update(_table, {'is_completed': completed ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Delete ───────────────────────────────────
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Count ────────────────────────────────────
  Future<int> countPending() async {
    final db = await _db;
    final result = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM $_table WHERE is_completed = 0');
    return (result.first['cnt'] as int?) ?? 0;
  }
}
