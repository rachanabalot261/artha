import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../security/key_manager.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();

  // Lazy initialization — only opens DB when first accessed
  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'artha_secure.db');
    final key = await KeyManager.instance.getOrCreateKey();

    return openDatabase(
      path,
      version: 1,
      password: key,    // ← this one line enables AES-256 encryption
      onCreate: _onCreate,
    );
  }

  // Runs once when app is installed — creates tables and inserts defaults
  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE transactions (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT    NOT NULL,
        amount   REAL    NOT NULL,
        category TEXT    NOT NULL,
        type     TEXT    NOT NULL,
        date     TEXT    NOT NULL,
        source   TEXT    NOT NULL,
        raw_sms  TEXT,
        account  TEXT,
        upi_ref  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        name   TEXT NOT NULL UNIQUE,
        icon   TEXT NOT NULL,
        color  TEXT NOT NULL,
        budget REAL
      )
    ''');

    // Pre-fill with default categories
    for (final c in CategoryModel.defaults()) {
      await db.insert('categories', c.toMap());
    }
  }

  // ─── INSERT ───────────────────────────────────────────────────

  Future<int> insert(TransactionModel t) async {
    final db = await database;
    // Prevent duplicate SMS transactions using UPI reference number
    if (t.upiRef != null) {
      final dup = await db.query('transactions',
          where: 'upi_ref = ?', whereArgs: [t.upiRef]);
      if (dup.isNotEmpty) return -1; // already exists
    }
    return db.insert('transactions', t.toMap());
  }

  // ─── QUERIES ──────────────────────────────────────────────────

  // Get all transactions for one specific month
  Future<List<TransactionModel>> byMonth(int y, int m) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        DateTime(y, m).toIso8601String(),
        DateTime(y, m + 1).toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  // Get transactions in a date range (used for "last 7 days")
  Future<List<TransactionModel>> byRange(
      DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        from.toIso8601String(),
        to.toIso8601String()
      ],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  // Sum spending by category for one month — used for pie chart
  Future<Map<String, double>> categoryTotals(int y, int m) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE date >= ? AND date < ? AND type = 'debit'
      GROUP BY category ORDER BY total DESC
    ''', [
      DateTime(y, m).toIso8601String(),
      DateTime(y, m + 1).toIso8601String(),
    ]);
    return {
      for (final r in rows)
        r['category'] as String: (r['total'] as num).toDouble()
    };
  }

  // Total money received this month
  Future<double> income(int y, int m) async {
    final db = await database;
    final r = await db.rawQuery('''
      SELECT SUM(amount) as t FROM transactions
      WHERE date >= ? AND date < ? AND type = 'credit'
    ''', [
      DateTime(y, m).toIso8601String(),
      DateTime(y, m + 1).toIso8601String()
    ]);
    return (r.first['t'] as num?)?.toDouble() ?? 0;
  }

  // Total money spent this month
  Future<double> spent(int y, int m) async {
    final db = await database;
    final r = await db.rawQuery('''
      SELECT SUM(amount) as t FROM transactions
      WHERE date >= ? AND date < ? AND type = 'debit'
    ''', [
      DateTime(y, m).toIso8601String(),
      DateTime(y, m + 1).toIso8601String()
    ]);
    return (r.first['t'] as num?)?.toDouble() ?? 0;
  }

  // Monthly totals for last 6 months — used for bar chart
  Future<List<Map<String, dynamic>>> trend6Months() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        strftime('%Y-%m', date) as month,
        SUM(CASE WHEN type='debit'  THEN amount ELSE 0 END) as spent,
        SUM(CASE WHEN type='credit' THEN amount ELSE 0 END) as income
      FROM transactions
      WHERE date >= date('now','-6 months')
      GROUP BY month ORDER BY month ASC
    ''');
  }

  // ─── DELETE / UPDATE ──────────────────────────────────────────

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('transactions',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(TransactionModel t) async {
    final db = await database;
    return db.update('transactions', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  // ─── CATEGORIES ───────────────────────────────────────────────

  Future<List<CategoryModel>> categories() async {
    final db = await database;
    return (await db.query('categories', orderBy: 'name'))
        .map(CategoryModel.fromMap)
        .toList();
  }

  Future<void> setBudget(String name, double budget) async {
    final db = await database;
    await db.update('categories', {'budget': budget},
        where: 'name = ?', whereArgs: [name]);
  }

  // ─── AI CONTEXT BUILDER ───────────────────────────────────────

  // Builds a text summary of your finances to send to the AI model
  // The AI never touches the database directly — it only sees this text
  Future<String> buildContext() async {
    final now = DateTime.now();
    final cats = await categoryTotals(now.year, now.month);
    final inc = await income(now.year, now.month);
    final sp = await spent(now.year, now.month);
    final trend = await trend6Months();
    final recent = await byRange(
        now.subtract(const Duration(days: 7)), now);

    final b = StringBuffer();
    b.writeln('=== USER FINANCIAL DATA ===');
    b.writeln('Month: ${_mn(now.month)} ${now.year}');
    b.writeln('Income:  ₹${inc.toStringAsFixed(0)}');
    b.writeln('Spent:   ₹${sp.toStringAsFixed(0)}');
    b.writeln('Saved:   ₹${(inc - sp).toStringAsFixed(0)}');
    b.writeln('');
    b.writeln('Category Breakdown:');
    cats.forEach(
        (k, v) => b.writeln('  $k: ₹${v.toStringAsFixed(0)}'));
    b.writeln('');
    b.writeln('Last 7 Days:');
    for (final t in recent.take(12)) {
      b.writeln(
          '  ${t.date.day}/${t.date.month} ${t.merchant}: ₹${t.amount.toStringAsFixed(0)} [${t.category}]');
    }
    b.writeln('');
    b.writeln('6-Month Trend:');
    for (final r in trend) {
      b.writeln(
          '  ${r['month']}: spent ₹${(r['spent'] as num).toStringAsFixed(0)} income ₹${(r['income'] as num).toStringAsFixed(0)}');
    }
    return b.toString();
  }

  String _mn(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}