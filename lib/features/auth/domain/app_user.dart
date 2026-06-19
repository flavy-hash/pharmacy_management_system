import '../../../core/constants/app_constants.dart';

/// An application user (Administrator or Pharmacist).
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Builds a user from a database row (which also contains credential columns
  /// that are intentionally not exposed on the model).
  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as String,
        username: map['username'] as String,
        fullName: map['full_name'] as String,
        role: UserRoleX.fromStorage(map['role'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
