import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_provider.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/role.dart';

/// Authentication state: the signed-in user (or null), plus loading/error.
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isRestoring = true,
  });

  final AppUser? user;
  final bool isLoading;
  final String? error;

  /// True while we are restoring a persisted session on startup.
  final bool isRestoring;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isRestoring,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._prefs) : super(const AuthState()) {
    _restore();
  }

  final AuthRepository _repo;
  final SharedPreferences _prefs;

  Future<void> _restore() async {
    final id = _prefs.getString(AppConstants.prefSessionUserId);
    if (id == null) {
      state = state.copyWith(isRestoring: false);
      return;
    }
    final user = await _repo.getById(id);
    state = state.copyWith(
      user: user,
      isRestoring: false,
      clearUser: user == null,
    );
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(username, password);
      await _prefs.setString(AppConstants.prefSessionUserId, user.id);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  /// Updates the signed-in user's name (and optionally password), then
  /// refreshes the in-memory session so the UI reflects the new name.
  Future<void> updateProfile({
    required String fullName,
    String password = '',
  }) async {
    final current = state.user;
    if (current == null) return;
    final updated = await _repo.updateProfile(
      id: current.id,
      fullName: fullName,
      password: password,
    );
    state = state.copyWith(user: updated);
  }

  Future<void> logout() async {
    await _prefs.remove(AppConstants.prefSessionUserId);
    state = const AuthState(isRestoring: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(sharedPreferencesProvider),
    );
  },
);

/// Convenience accessor for the current user.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authControllerProvider).user,
);

/// All registered users (admin user-management screen).
final usersProvider = FutureProvider<List<AppUser>>((ref) {
  // Re-read whenever the signed-in user changes (e.g. after creating one).
  ref.watch(authControllerProvider);
  return ref.watch(authRepositoryProvider).getAll();
});

/// All roles (admin role-management screen and the add-user dropdown).
final rolesProvider = FutureProvider<List<Role>>((ref) {
  return ref.watch(authRepositoryProvider).getRoles();
});
