import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_logout_bus.dart';
import '../core/constants/storage_keys.dart';
import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../data/models/auth/current_user.dart';
import '../data/models/auth/token_response.dart';
import '../data/repositories/auth_repository.dart';

// ── Auth Status ───────────────────────────────────────────────────────────────

enum AuthStatus {
  /// App just launched; no attempt to restore session yet.
  initial,

  /// Restoring or refreshing session.
  loading,

  /// Valid session exists.
  authenticated,

  /// No session / session expired.
  unauthenticated,

  /// Login / OTP / reset call returned an error.
  error,
}

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.currentUser,
    this.error,
  });

  final AuthStatus status;
  final CurrentUser? currentUser;

  /// Non-null when [status] is [AuthStatus.error].
  final String? error;

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.initial || status == AuthStatus.loading;
  bool get isInitialized => status != AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    CurrentUser? currentUser,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      currentUser: currentUser ?? this.currentUser,
      error: error,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, user: ${currentUser?.id}, error: $error)';
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required AuthRepository authRepo,
    required SecureStorage secureStorage,
    required LocalStorage localStorage,
  })  : _authRepo = authRepo,
        _secureStorage = secureStorage,
        _localStorage = localStorage,
        super(const AuthState()) {
    _subscribeToLogoutBus();
  }

  final AuthRepository _authRepo;
  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;
  StreamSubscription<void>? _logoutSubscription;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void _subscribeToLogoutBus() {
    _logoutSubscription = AuthLogoutBus.instance.stream.listen((_) {
      if (state.isAuthenticated) {
        _clearLocalData();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    super.dispose();
  }

  // ── Initialize (called from SplashScreen) ─────────────────────────────────

  Future<void> initialize() async {
    if (state.status == AuthStatus.loading) return;
    state = const AuthState(status: AuthStatus.loading);

    try {
      final token = await _secureStorage.readToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      // Try to restore user from local storage first (fast path).
      final cachedUserJson = _localStorage.getString(StorageKeys.currentUser);
      CurrentUser? cachedUser;
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          cachedUser =
              CurrentUser.fromJson(jsonDecode(cachedUserJson) as Map<String, dynamic>);
        } catch (_) {}
      }

      // Validate token by fetching fresh user from the server.
      final user = await _authRepo.getMe();
      await _persistUser(user);
      state = AuthState(status: AuthStatus.authenticated, currentUser: user);
    } on AppException {
      // Token invalid / expired / server error → force unauthenticated.
      await _clearLocalData();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      await _clearLocalData();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final tokenResponse = await _authRepo.login(
        email: email,
        phone: phone,
        password: password,
      );
      await _secureStorage.writeToken(tokenResponse.accessToken);
      await _secureStorage.writeRefreshToken(tokenResponse.refreshToken);

      final user = await _authRepo.getMe();
      await _persistUser(user);

      state = AuthState(
        status: AuthStatus.authenticated,
        currentUser: user,
      );
    } on AppException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.readRefreshToken();
      await _authRepo.logout(refreshToken: refreshToken);
    } catch (_) {
      // Logout is best-effort; always clear local state.
    } finally {
      await _clearLocalData();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── Clear error ───────────────────────────────────────────────────────────

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _persistUser(CurrentUser user) async {
    await _localStorage.setString(
      StorageKeys.currentUser,
      jsonEncode(user.toJson()),
    );
    if (user.schoolId != null) {
      await _localStorage.setString(StorageKeys.schoolId, user.schoolId!);
    }
    if (user.role == UserRole.parent && user.parentId != null) {
      await _localStorage.setString(StorageKeys.parentId, user.parentId!);
    }
    await _localStorage.setString(StorageKeys.userRole, user.role.backendValue);
  }

  Future<void> _clearLocalData() async {
    await _secureStorage.clearAll();
    await _localStorage.remove(StorageKeys.currentUser);
    await _localStorage.remove(StorageKeys.schoolId);
    await _localStorage.remove(StorageKeys.parentId);
    await _localStorage.remove(StorageKeys.userRole);
    await _localStorage.remove(StorageKeys.selectedChildId);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepo: ref.read(authRepositoryProvider),
    secureStorage: ref.read(secureStorageProvider),
    localStorage: ref.read(localStorageProvider),
  );
});

/// Convenience provider to access only the [CurrentUser] (nullable).
final currentUserProvider = Provider<CurrentUser?>((ref) {
  return ref.watch(authNotifierProvider).currentUser;
});