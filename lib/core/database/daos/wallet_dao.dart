// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/wallet.dart';

class WalletDao {
  WalletDao._();
  static final WalletDao instance = WalletDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;
  static const String _table = 'wallets';

  // ── Create ───────────────────────────────────
  Future<int> insert(Wallet wallet) async {
    final db = await _db;
    return db.insert(_table, wallet.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // ── Read ─────────────────────────────────────
  Future<List<Wallet>> getAll() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'created_at ASC');
    return rows.map(Wallet.fromMap).toList();
  }

  Future<Wallet?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Wallet.fromMap(rows.first);
  }

  Future<List<Wallet>> getByCurrency(String currencyCode) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'currency_code = ?',
        whereArgs: [currencyCode],
        orderBy: 'created_at ASC');
    return rows.map(Wallet.fromMap).toList();
  }

  // ── Update ───────────────────────────────────
  Future<int> update(Wallet wallet) async {
    final db = await _db;
    return db.update(_table, wallet.toMap(),
        where: 'id = ?',
        whereArgs: [wallet.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> adjustBalance(int walletId, double delta) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(_table,
          columns: ['balance'],
          where: 'id = ?',
          whereArgs: [walletId],
          limit: 1);
      if (rows.isEmpty) return;
      final current = (rows.first['balance'] as num).toDouble();
      await txn.update(_table, {'balance': current + delta},
          where: 'id = ?', whereArgs: [walletId]);
    });
  }

  Future<void> setBalance(int walletId, double balance) async {
    final db = await _db;
    await db.update(_table, {'balance': balance},
        where: 'id = ?', whereArgs: [walletId]);
  }

  // ── Delete ───────────────────────────────────
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Aggregates ───────────────────────────────
  Future<double> totalBalanceForCurrency(String currencyCode) async {
    final db = await _db;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(balance), 0) AS total '
        'FROM $_table WHERE currency_code = ?',
        [currencyCode]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> count() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS cnt FROM $_table');
    return (result.first['cnt'] as int?) ?? 0;
  }
}
