import 'permissions.dart';

/// An application user. [role] is the name of the assigned role, [isAdmin]
/// reflects whether that role grants administrator privileges, and
/// [permissions] is the set of permission keys the role allows.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isAdmin,
    required this.permissions,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String fullName;

  /// The name of the user's role, e.g. `Administrator` or a custom role.
  final String role;

  /// Whether the assigned role grants administrator privileges (all access).
  final bool isAdmin;

  /// Permission keys granted by the role (ignored when [isAdmin] is true).
  final Set<String> permissions;

  final DateTime createdAt;

  /// Whether this user may perform [permission]. Administrators can do anything.
  bool can(AppPermission permission) =>
      isAdmin || permissions.contains(permission.key);

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Builds a user from an API row (which also contains credential columns
  /// that are intentionally not exposed on the model).
  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as String,
    username: map['username'] as String,
    fullName: map['full_name'] as String,
    role: map['role'] as String? ?? '',
    isAdmin: map['is_admin'] == true || map['is_admin'] == 1,
    permissions: _permsOf(map['permissions']),
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  static Set<String> _permsOf(Object? raw) {
    if (raw is List) return raw.map((e) => e.toString()).toSet();
    return <String>{};
  }
}
