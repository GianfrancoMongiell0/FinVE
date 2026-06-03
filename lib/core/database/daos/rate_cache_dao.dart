// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/rate.dart';

class RateCacheDao {
  RateCacheDao._();
  static final RateCacheDao instance = RateCacheDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;
  static const String _table = 'rate_cache';

  // ── Upsert ───────────────────────────────────
  Future<void> upsert(String currencyPair, double rate) async {
    final db = await _db;
    await db.insert(
      _table,
      Rate(
        currencyPair: currencyPair,
        rate: rate,
        fetchedAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(Map<String, double> rates) async {
    final db = await _db;
    final now = DateTime.now();
    await db.transaction((txn) async {
      for (final entry in rates.entries) {
        await txn.insert(
          _table,
          Rate(
            currencyPair: entry.key,
            rate: entry.value,
            fetchedAt: now,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ── Read ─────────────────────────────────────
  Future<Rate?> get(String currencyPair) async {
    final db = await _db;
    final rows = await db.query(_table,
        where: 'currency_pair = ?', whereArgs: [currencyPair], limit: 1);
    return rows.isEmpty ? null : Rate.fromMap(rows.first);
  }

  Future<List<Rate>> getAll() async {
    final db = await _db;
    final rows =
        await db.query(_table, orderBy: 'currency_pair ASC');
    return rows.map(Rate.fromMap).toList();
  }

  Future<DateTime?> getLastFetchedAt(String currencyPair) async {
    final rate = await get(currencyPair);
    return rate?.fetchedAt;
  }

  Future<bool> isStale(String currencyPair,
      {Duration maxAge = const Duration(minutes: 30)}) async {
    final fetchedAt = await getLastFetchedAt(currencyPair);
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) > maxAge;
  }

  // ── Delete ───────────────────────────────────
  Future<int> delete(String currencyPair) async {
    final db = await _db;
    return db.delete(_table,
        where: 'currency_pair = ?', whereArgs: [currencyPair]);
  }

  Future<int> deleteAll() async {
    final db = await _db;
    return db.delete(_table);
  }
}
