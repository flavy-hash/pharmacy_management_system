import '../../../core/database/app_database.dart';
import '../domain/medicine.dart';

/// Data access for the `medicines` table.
class MedicineRepository {
  MedicineRepository(this._db);

  final AppDatabase _db;

  Future<List<Medicine>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('medicines', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Medicine.fromMap).toList();
  }

  Future<Medicine?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('medicines',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Medicine.fromMap(rows.first);
  }

  Future<void> insert(Medicine medicine) async {
    final db = await _db.database;
    await db.insert('medicines', medicine.toMap());
  }

  Future<void> update(Medicine medicine) async {
    final db = await _db.database;
    await db.update(
      'medicines',
      medicine.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  /// Atomically decrements stock for a medicine (used when finalising a sale).
  Future<void> decrementStock(String id, int by) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE medicines SET quantity = MAX(quantity - ?, 0), '
      'updated_at = ? WHERE id = ?',
      [by, DateTime.now().toIso8601String(), id],
    );
  }
}
