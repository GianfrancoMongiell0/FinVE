// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/transaction.dart' as app_models;

class TransactionDao {
  TransactionDao._();
  static final TransactionDao instance = TransactionDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;
  static const String _table = 'transactions';

  Future<int> insert(app_models.Transaction tx) async {
    final db = await _db;
    return db.insert(_table, tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<app_models.Transaction?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : app_models.Transaction.fromMap(rows.first);
  }

  Future<List<app_models.Transaction>> getFiltered({
    int? walletId,
    int? categoryId,
    String? type,
    String? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchNote,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (walletId != null) { conditions.add('wallet_id = ?'); args.add(walletId); }
    if (categoryId != null) { conditions.add('category_id = ?'); args.add(categoryId); }
    if (type != null) { conditions.add('type = ?'); args.add(type); }
    if (paymentMethod != null) { conditions.add('payment_method = ?'); args.add(paymentMethod); }
    if (dateFrom != null) { conditions.add('date >= ?'); args.add(dateFrom.toIso8601String()); }
    if (dateTo != null) { conditions.add('date <= ?'); args.add(dateTo.toIso8601String()); }
    if (searchNote != null && searchNote.isNotEmpty) {
      conditions.add('note LIKE ?');
      args.add('%$searchNote%');
    }

    final rows = await db.query(
      _table,
      where: conditions.isNotEmpty ? conditions.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(app_models.Transaction.fromMap).toList();
  }

  Future<List<app_models.Transaction>> getRecent(int n) => getFiltered(limit: n);

  Future<Map<String, double>> sumByType(int walletId,
      {DateTime? from, DateTime? to}) async {
    final db = await _db;
    final cond = StringBuffer('wallet_id = ?');
    final args = <dynamic>[walletId];
    if (from != null) { cond.write(' AND date >= ?'); args.add(from.toIso8601String()); }
    if (to != null) { cond.write(' AND date <= ?'); args.add(to.toIso8601String()); }

    final rows = await db.rawQuery(
      'SELECT type, COALESCE(SUM(amount), 0) AS total '
      'FROM $_table WHERE $cond GROUP BY type',
      args,
    );
    double income = 0, expense = 0;
    for (final r in rows) {
      if (r['type'] == 'income') income = (r['total'] as num).toDouble();
      else expense = (r['total'] as num).toDouble();
    }
    return {'income': income, 'expense': expense};
  }

  Future<List<Map<String, dynamic>>> dailyNetAllWallets({int days = 30}) async {
    final db = await _db;
    final from = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return db.rawQuery('''
      SELECT
        substr(date, 1, 10) AS day,
        SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END) -
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS net
      FROM $_table
      WHERE date >= ?
      GROUP BY day
      ORDER BY day ASC
    ''', [from]);
  }

  Future<int> update(app_models.Transaction tx) async {
    final db = await _db;
    return db.update(_table, tx.toMap(),
        where: 'id = ?',
        whereArgs: [tx.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByWallet(int walletId) async {
    final db = await _db;
    return db.delete(_table, where: 'wallet_id = ?', whereArgs: [walletId]);
  }

  Future<int> count({int? walletId}) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $_table'
      '${walletId != null ? ' WHERE wallet_id = $walletId' : ''}',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }
}
