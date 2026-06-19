import '../../../core/api/api_client.dart';
import '../domain/app_user.dart';
import '../domain/role.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the `auth.php` and `roles.php` endpoints for credential checks,
/// user management and role management.
///
/// Passwords are verified server-side (bcrypt); the client never sees the hash.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Verifies credentials and returns the matching user, or throws
  /// [AuthException] on failure (bad username/password or a network error).
  Future<AppUser> login(String username, String password) async {
    try {
      final data = await _api.post('auth.php?action=login', {
        'username': username.trim(),
        'password': password,
      });
      return AppUser.fromMap(Map<String, Object?>.from(data as Map));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<AppUser?> getById(String id) async {
    try {
      final data = await _api.get('auth.php', {'action': 'get', 'id': id});
      if (data == null) return null;
      return AppUser.fromMap(Map<String, Object?>.from(data as Map));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<AppUser>> getAll() async {
    final data = await _api.get('auth.php', {'action': 'list'});
    return (data as List)
        .map((e) => AppUser.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
  }

  /// Creates a new user with the given role name (admin-only operation).
  Future<AppUser> createUser({
    required String username,
    required String fullName,
    required String password,
    required String role,
  }) async {
    try {
      final data = await _api.post('auth.php?action=create', {
        'username': username.trim(),
        'full_name': fullName.trim(),
        'password': password,
        'role': role,
      });
      return AppUser.fromMap(Map<String, Object?>.from(data as Map));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Deletes a user. [requesterId] is the signed-in admin's id — the server
  /// refuses to let an admin delete their own account.
  Future<void> deleteUser({
    required String id,
    required String requesterId,
  }) async {
    try {
      await _api.post('auth.php?action=delete', {
        'id': id,
        'requester_id': requesterId,
      });
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Updates the current user's display name and, optionally, password.
  /// Pass a non-empty [password] to change it; leave it empty to keep the
  /// existing one.
  Future<AppUser> updateProfile({
    required String id,
    required String fullName,
    String password = '',
  }) async {
    try {
      final data = await _api.post('auth.php?action=update_profile', {
        'id': id,
        'full_name': fullName.trim(),
        'password': password,
      });
      return AppUser.fromMap(Map<String, Object?>.from(data as Map));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  // --- Roles ---

  Future<List<Role>> getRoles() async {
    final data = await _api.get('roles.php', {'action': 'list'});
    return (data as List)
        .map((e) => Role.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
  }

  Future<Role> createRole({
    required String name,
    required bool isAdmin,
    required Set<String> permissions,
  }) async {
    try {
      final data = await _api.post('roles.php?action=create', {
        'name': name.trim(),
        'is_admin': isAdmin,
        'permissions': permissions.toList(),
      });
      return Role.fromMap(Map<String, Object?>.from(data as Map));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await _api.post('roles.php?action=delete', {'id': id});
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }
}
