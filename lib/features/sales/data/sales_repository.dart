import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/sale.dart';

/// Data access for `sales` and `sale_items`, including stock-deducting
/// transactional checkout.
class SalesRepository {
  SalesRepository(this._db);

  final AppDatabase _db;

  /// Persists a sale, its line items, and deducts stock — all in one
  /// transaction so the inventory can never drift from the sales ledger.
  Future<void> recordSale(Sale sale) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('sales', sale.toMap());
      for (final item in sale.items) {
        await txn.insert('sale_items', item.toMap());
        await txn.rawUpdate(
          'UPDATE medicines SET quantity = MAX(quantity - ?, 0), '
          'updated_at = ? WHERE id = ?',
          [item.quantity, sale.createdAt.toIso8601String(), item.medicineId],
        );
      }
    });
  }

  Future<List<Sale>> getRecent({int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.query('sales',
        orderBy: 'created_at DESC', limit: limit);
    return rows.map((r) => Sale.fromMap(r)).toList();
  }

  Future<List<Sale>> getInRange(DateTime start, DateTime end,
      {bool withItems = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'sales',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    if (!withItems) return rows.map((r) => Sale.fromMap(r)).toList();

    final sales = <Sale>[];
    for (final row in rows) {
      final items = await _itemsFor(db, row['id'] as String);
      sales.add(Sale.fromMap(row, items: items));
    }
    return sales;
  }

  Future<Sale?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('sales', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final items = await _itemsFor(db, id);
    return Sale.fromMap(rows.first, items: items);
  }

  Future<List<SaleItem>> _itemsFor(Database db, String saleId) async {
    final rows = await db
        .query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    return rows.map(SaleItem.fromMap).toList();
  }

  /// Sum of `total` across all sales (optionally within a date range).
  Future<double> totalRevenue({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    final hasRange = start != null && end != null;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) AS revenue FROM sales'
      '${hasRange ? ' WHERE created_at >= ? AND created_at < ?' : ''}',
      hasRange ? [start.toIso8601String(), end.toIso8601String()] : null,
    );
    return (result.first['revenue'] as num).toDouble();
  }
}
