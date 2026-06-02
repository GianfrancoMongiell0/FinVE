import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  // Bump this number whenever the schema changes and add a migration block.
  static const int _kVersion = 2;
  static const String _kDbName = 'finve.db';

  // ─────────────────────────────────────────────
  //  Public accessor
  // ─────────────────────────────────────────────
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // ─────────────────────────────────────────────
  //  Initialisation
  // ─────────────────────────────────────────────
  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _kDbName);

    return openDatabase(
      path,
      version: _kVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign keys on every connection.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ─────────────────────────────────────────────
  //  Schema — v1
  // ─────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute(_sqlCreateWallets);
      await txn.execute(_sqlCreateCategories);
      await txn.execute(_sqlCreateTransactions);
      await txn.execute(_sqlCreatePriorities);
      await txn.execute(_sqlCreateRecurringExpenses);
      await txn.execute(_sqlCreateRateCache);
      await txn.execute(_sqlCreateBudgets);
      await _seedCategories(txn);
    });

    debugPrint('[DB] Created schema v$version');
  }

  // ─────────────────────────────────────────────
  //  Migrations
  // ─────────────────────────────────────────────
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('[DB] Upgrading $oldVersion → $newVersion');
    if (oldVersion < 2) {
      await db.execute(_sqlCreateBudgets);
      debugPrint('[DB] Migration v2: budgets table created');
    }
  }

  // ─────────────────────────────────────────────
  //  CREATE TABLE statements
  // ─────────────────────────────────────────────
  static const String _sqlCreateWallets = '''
    CREATE TABLE wallets (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      currency_code TEXT  NOT NULL DEFAULT 'USD',
      balance     REAL    NOT NULL DEFAULT 0.0,
      icon        TEXT    NOT NULL DEFAULT 'wallet',
      created_at  TEXT    NOT NULL
    )
  ''';

  static const String _sqlCreateCategories = '''
    CREATE TABLE categories (
      id    INTEGER PRIMARY KEY AUTOINCREMENT,
      name  TEXT    NOT NULL,
      icon  TEXT    NOT NULL,
      color TEXT    NOT NULL,
      type  TEXT    NOT NULL CHECK(type IN ('income','expense','both'))
    )
  ''';

  static const String _sqlCreateTransactions = '''
    CREATE TABLE transactions (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      wallet_id      INTEGER NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
      amount         REAL    NOT NULL,
      type           TEXT    NOT NULL CHECK(type IN ('income','expense')),
      category_id    INTEGER REFERENCES categories(id) ON DELETE SET NULL,
      payment_method TEXT    NOT NULL DEFAULT 'cash'
                             CHECK(payment_method IN
                               ('cash','pago_movil','transfer','zelle','other')),
      note           TEXT,
      date           TEXT    NOT NULL,
      created_at     TEXT    NOT NULL
    )
  ''';

  static const String _sqlCreatePriorities = '''
    CREATE TABLE priorities (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      name           TEXT    NOT NULL,
      target_amount  REAL    NOT NULL,
      currency_code  TEXT    NOT NULL DEFAULT 'USD',
      priority_level TEXT    NOT NULL DEFAULT 'medium'
                             CHECK(priority_level IN ('high','medium','low')),
      is_completed   INTEGER NOT NULL DEFAULT 0,
      notes          TEXT,
      created_at     TEXT    NOT NULL
    )
  ''';

  static const String _sqlCreateRecurringExpenses = '''
    CREATE TABLE recurring_expenses (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      name            TEXT    NOT NULL,
      amount          REAL    NOT NULL,
      currency_code   TEXT    NOT NULL DEFAULT 'USD',
      wallet_id       INTEGER NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
      category_id     INTEGER REFERENCES categories(id) ON DELETE SET NULL,
      payment_method  TEXT    NOT NULL DEFAULT 'cash'
                              CHECK(payment_method IN
                                ('cash','pago_movil','transfer','zelle','other')),
      day_of_month    INTEGER NOT NULL CHECK(day_of_month BETWEEN 1 AND 31),
      auto_register   INTEGER NOT NULL DEFAULT 0,
      last_triggered_at TEXT,
      created_at      TEXT    NOT NULL
    )
  ''';

  static const String _sqlCreateRateCache = '''
    CREATE TABLE rate_cache (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      currency_pair TEXT    NOT NULL UNIQUE,
      rate          REAL    NOT NULL,
      fetched_at    TEXT    NOT NULL
    )
  ''';

  static const String _sqlCreateBudgets = '''
    CREATE TABLE IF NOT EXISTS budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      currency_code TEXT NOT NULL DEFAULT 'USD',
      month INTEGER NOT NULL,
      year INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
      UNIQUE(category_id, month, year)
    )
  ''';

  // ─────────────────────────────────────────────
  //  Default category seed data
  // ─────────────────────────────────────────────
  Future<void> _seedCategories(DatabaseExecutor txn) async {
    const categories = [
      // Expense categories
      {'name': 'Comida',         'icon': '🍔', 'color': '#FF6B35', 'type': 'expense'},
      {'name': 'Transporte',     'icon': '🚗', 'color': '#4ECDC4', 'type': 'expense'},
      {'name': 'Servicios',      'icon': '💡', 'color': '#FFE66D', 'type': 'expense'},
      {'name': 'Salud',          'icon': '💊', 'color': '#FF6B9D', 'type': 'expense'},
      {'name': 'Entretenimiento','icon': '🎮', 'color': '#C3A6FF', 'type': 'expense'},
      {'name': 'Hogar',          'icon': '🏠', 'color': '#A8E6CF', 'type': 'expense'},
      {'name': 'Ropa',           'icon': '👕', 'color': '#FFB347', 'type': 'expense'},
      {'name': 'Educación',      'icon': '📚', 'color': '#87CEEB', 'type': 'expense'},
      {'name': 'Otros gastos',   'icon': '📦', 'color': '#B0BEC5', 'type': 'expense'},
      // Income categories
      {'name': 'Trabajo',        'icon': '💼', 'color': '#1D9E75', 'type': 'income'},
      {'name': 'Freelance',      'icon': '💻', 'color': '#378ADD', 'type': 'income'},
      {'name': 'Inversión',      'icon': '📈', 'color': '#EF9F27', 'type': 'income'},
      {'name': 'Regalo',         'icon': '🎁', 'color': '#FF85A1', 'type': 'income'},
      {'name': 'Otros ingresos', 'icon': '💰', 'color': '#5DCAA5', 'type': 'income'},
    ];

    for (final cat in categories) {
      await txn.insert('categories', cat);
    }
    debugPrint('[DB] Seeded ${categories.length} default categories');
  }

  // ─────────────────────────────────────────────
  //  Utility: close (for testing)
  // ─────────────────────────────────────────────
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Wipes and recreates the database (dev/debug only).
  Future<void> resetForTesting() async {
    assert(kDebugMode, 'resetForTesting must only be used in debug mode');
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _kDbName);
    await close();
    await deleteDatabase(path);
    _db = await _initDb();
  }
}