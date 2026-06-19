import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../utils/password_hasher.dart';

/// Owns the SQLite connection, schema creation and one-time seeding.
///
/// The repositories depend on this single instance so the whole app shares one
/// database handle. Swapping this class for a Firestore/REST implementation
/// would let the rest of the app stay unchanged.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'pharmacare.db';
  static const _dbVersion = 1;
  static const _uuid = Uuid();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    // Use the FFI implementation on desktop platforms (Windows/Linux/macOS);
    // the mobile platforms use the default plugin.
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id            TEXT PRIMARY KEY,
        username      TEXT NOT NULL UNIQUE,
        full_name     TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        salt          TEXT NOT NULL,
        role          TEXT NOT NULL,
        created_at    TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medicines (
        id                 TEXT PRIMARY KEY,
        name               TEXT NOT NULL,
        category           TEXT NOT NULL,
        batch_number       TEXT NOT NULL,
        manufacturer       TEXT NOT NULL,
        quantity           INTEGER NOT NULL,
        initial_quantity   INTEGER NOT NULL,
        reorder_level      INTEGER NOT NULL,
        purchase_price     REAL NOT NULL,
        selling_price      REAL NOT NULL,
        manufacturing_date TEXT NOT NULL,
        expiry_date        TEXT NOT NULL,
        created_at         TEXT NOT NULL,
        updated_at         TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id                TEXT PRIMARY KEY,
        invoice_number    TEXT NOT NULL,
        customer_name     TEXT,
        subtotal          REAL NOT NULL,
        discount          REAL NOT NULL,
        tax               REAL NOT NULL,
        total             REAL NOT NULL,
        payment_method    TEXT NOT NULL,
        payment_reference TEXT,
        cashier_id        TEXT,
        cashier_name      TEXT,
        created_at        TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id            TEXT PRIMARY KEY,
        sale_id       TEXT NOT NULL,
        medicine_id   TEXT NOT NULL,
        medicine_name TEXT NOT NULL,
        quantity      INTEGER NOT NULL,
        unit_price    REAL NOT NULL,
        subtotal      REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await _seed(db);
  }

  /// Inserts default users and a small demo inventory so the app is usable on
  /// first launch.
  Future<void> _seed(Database db) async {
    final now = DateTime.now();

    Map<String, Object?> buildUser(
        String username, String fullName, String password, UserRole role) {
      final salt = PasswordHasher.generateSalt();
      return {
        'id': _uuid.v4(),
        'username': username,
        'full_name': fullName,
        'password_hash': PasswordHasher.hash(password, salt),
        'salt': salt,
        'role': role.storageValue,
        'created_at': now.toIso8601String(),
      };
    }

    final batch = db.batch();
    batch.insert(
        'users', buildUser('admin', 'System Administrator', 'admin123', UserRole.admin));
    batch.insert('users',
        buildUser('pharmacist', 'Jane Pharmacist', 'pharma123', UserRole.pharmacist));

    for (final seed in _seedMedicines(now)) {
      batch.insert('medicines', seed);
    }
    await batch.commit(noResult: true);
  }

  List<Map<String, Object?>> _seedMedicines(DateTime now) {
    Map<String, Object?> med({
      required String name,
      required String category,
      required String batch,
      required String maker,
      required int qty,
      required int initial,
      required int reorder,
      required double cost,
      required double price,
      required int monthsMfg,
      required int daysToExpiry,
    }) {
      return {
        'id': _uuid.v4(),
        'name': name,
        'category': category,
        'batch_number': batch,
        'manufacturer': maker,
        'quantity': qty,
        'initial_quantity': initial,
        'reorder_level': reorder,
        'purchase_price': cost,
        'selling_price': price,
        'manufacturing_date':
            DateTime(now.year, now.month - monthsMfg, now.day)
                .toIso8601String(),
        'expiry_date':
            now.add(Duration(days: daysToExpiry)).toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
    }

    return [
      med(name: 'Paracetamol 500mg', category: 'Analgesic', batch: 'PCM-2401', maker: 'Shelys Pharma', qty: 320, initial: 500, reorder: 80, cost: 50, price: 120, monthsMfg: 6, daysToExpiry: 400),
      med(name: 'Amoxicillin 250mg', category: 'Antibiotic', batch: 'AMX-1180', maker: 'Cosmos Ltd', qty: 40, initial: 300, reorder: 60, cost: 180, price: 350, monthsMfg: 8, daysToExpiry: 120),
      med(name: 'Coartem (ALU)', category: 'Antimalarial', batch: 'CTM-7782', maker: 'Novartis', qty: 0, initial: 200, reorder: 40, cost: 1200, price: 2500, monthsMfg: 4, daysToExpiry: 540),
      med(name: 'Vitamin C 1000mg', category: 'Vitamin', batch: 'VTC-0091', maker: 'HealthAid', qty: 150, initial: 250, reorder: 50, cost: 90, price: 200, monthsMfg: 3, daysToExpiry: 3),
      med(name: 'Ibuprofen 400mg', category: 'Analgesic', batch: 'IBU-3321', maker: 'Regal Pharma', qty: 90, initial: 200, reorder: 40, cost: 70, price: 180, monthsMfg: 5, daysToExpiry: -10),
      med(name: 'ORS Sachets', category: 'Supplement', batch: 'ORS-5567', maker: 'Kenya Pharma', qty: 210, initial: 400, reorder: 100, cost: 200, price: 450, monthsMfg: 2, daysToExpiry: 700),
      med(name: 'Cetirizine 10mg', category: 'Antihistamine', batch: 'CTZ-2210', maker: 'Elys Chemical', qty: 28, initial: 180, reorder: 35, cost: 60, price: 150, monthsMfg: 7, daysToExpiry: 45),
      med(name: 'Metformin 500mg', category: 'Cardiovascular', batch: 'MET-9090', maker: 'Cosmos Ltd', qty: 120, initial: 300, reorder: 60, cost: 110, price: 260, monthsMfg: 9, daysToExpiry: 260),
    ];
  }

  /// Generates a unique invoice number based on the current date.
  static String newInvoiceNumber(DateTime now) {
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = now.millisecondsSinceEpoch.remainder(100000).toString().padLeft(5, '0');
    return 'INV-$stamp-$suffix';
  }

  static String newId() => _uuid.v4();
}
