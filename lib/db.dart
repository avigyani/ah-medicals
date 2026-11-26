// DawaKhata — local SQLite storage (sqflite). Phone only, offline.
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDb {
  static final AppDb instance = AppDb._();
  AppDb._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'dawakhata.db'),
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, generic TEXT, company TEXT,
            category TEXT, batch TEXT NOT NULL, expiry TEXT NOT NULL,
            mrp REAL NOT NULL, purchasePrice REAL, sellingPrice REAL,
            stock INTEGER NOT NULL, minStock INTEGER,
            gst REAL, hsn TEXT, barcode TEXT, rack TEXT,
            supplier TEXT, rxRequired INTEGER, isSample INTEGER
          )''');
        await d.execute('''
          CREATE TABLE suppliers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, phone TEXT
          )''');
        await d.execute('''
          CREATE TABLE movements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medicineId INTEGER NOT NULL, medicineName TEXT NOT NULL,
            type TEXT NOT NULL, qty INTEGER NOT NULL,
            reason TEXT, date TEXT NOT NULL
          )''');
      },
    );
    return _db!;
  }

  // ---- Medicines ----
  Future<List<Medicine>> allMedicines() async {
    final d = await db;
    final rows = await d.query('medicines', orderBy: 'name COLLATE NOCASE');
    return rows.map(Medicine.fromMap).toList();
  }

  Future<int> insertMedicine(Medicine m) async {
    final d = await db;
    return d.insert('medicines', m.toMap()..remove('id'));
  }

  Future<int> updateMedicine(Medicine m) async {
    final d = await db;
    return d.update('medicines', m.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [m.id]);
  }

  Future<int> deleteMedicine(int id) async {
    final d = await db;
    return d.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> duplicateBatch(String name, String batch, int? ignoreId) async {
    final d = await db;
    final rows = await d.query('medicines',
        where: 'lower(name) = ? AND lower(batch) = ?',
        whereArgs: [name.toLowerCase(), batch.toLowerCase()]);
    return rows.any((r) => r['id'] != ignoreId);
  }

  Future<int> deleteAllSamples() async {
    final d = await db;
    return d.delete('medicines', where: 'isSample = 1');
  }

  // ---- Suppliers ----
  Future<List<Supplier>> allSuppliers() async {
    final d = await db;
    final rows = await d.query('suppliers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<int> insertSupplier(Supplier s) async {
    final d = await db;
    return d.insert('suppliers', s.toMap()..remove('id'));
  }

  Future<int> deleteSupplier(int id) async {
    final d = await db;
    return d.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Stock movements (transaction: stock change + log together) ----
  Future<void> addMovement(Medicine med, String type, int qty, String reason) async {
    final d = await db;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final newStock = type == 'IN' ? med.stock + qty : med.stock - qty;
    if (newStock < 0) throw StateError('Stock cannot go below zero');
    await d.transaction((txn) async {
      await txn.update('medicines', {'stock': newStock},
          where: 'id = ?', whereArgs: [med.id]);
      await txn.insert(
          'movements',
          StockMovement(
            medicineId: med.id!,
            medicineName: med.name,
            type: type,
            qty: qty,
            reason: reason,
            date: dateStr,
          ).toMap()
            ..remove('id'));
    });
  }

  Future<List<StockMovement>> allMovements() async {
    final d = await db;
    final rows = await d.query('movements', orderBy: 'id DESC', limit: 200);
    return rows.map(StockMovement.fromMap).toList();
  }
}
