import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/password_hasher.dart';
import '../domain/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Data access and credential checks for the `users` table.
class AuthRepository {
  AuthRepository(this._db);

  final AppDatabase _db;

  /// Verifies credentials and returns the matching user, or throws
  /// [AuthException] on failure.
  Future<AppUser> login(String username, String password) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw AuthException('No account found for "$username".');
    }
    final row = rows.first;
    final ok = PasswordHasher.verify(
      password,
      row['salt'] as String,
      row['password_hash'] as String,
    );
    if (!ok) throw AuthException('Incorrect password. Please try again.');
    return AppUser.fromMap(row);
  }

  Future<AppUser?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<List<AppUser>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('users', orderBy: 'created_at ASC');
    return rows.map(AppUser.fromMap).toList();
  }

  /// Creates a new user (admin-only operation in the UI).
  Future<AppUser> createUser({
    required String username,
    required String fullName,
    required String password,
    required UserRole role,
  }) async {
    final db = await _db.database;
    final normalised = username.trim().toLowerCase();
    final existing = await db.query('users',
        where: 'username = ?', whereArgs: [normalised], limit: 1);
    if (existing.isNotEmpty) {
      throw AuthException('Username "$username" is already taken.');
    }
    final salt = PasswordHasher.generateSalt();
    final id = AppDatabase.newId();
    final now = DateTime.now();
    await db.insert('users', {
      'id': id,
      'username': normalised,
      'full_name': fullName.trim(),
      'password_hash': PasswordHasher.hash(password, salt),
      'salt': salt,
      'role': role.storageValue,
      'created_at': now.toIso8601String(),
    });
    return AppUser(
      id: id,
      username: normalised,
      fullName: fullName.trim(),
      role: role,
      createdAt: now,
    );
  }
}
