import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_logout_bus.dart';
import '../core/constants/storage_keys.dart';
import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../data/models/auth/current_user.dart';
import '../data/repositories/auth_repository.dart';

// ── Auth Status ───────────────────────────────────────────────────────────────

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
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
  final String? error;

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

  // ── Initialize ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (state.status == AuthStatus.loading) return;
    state = const AuthState(status: AuthStatus.loading);

    try {
      final cachedUser = _readCachedUser();
      var token = await _secureStorage
          .readToken()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      // Fallback token source for hot-restart/reload resiliency.
      if (token == null || token.isEmpty) {
        final backup = _localStorage.getString(StorageKeys.accessTokenBackup);
        if (backup != null && backup.isNotEmpty) {
          token = backup;
          await _secureStorage.writeToken(backup);
          final refreshBackup =
              _localStorage.getString(StorageKeys.refreshTokenBackup);
          if (refreshBackup != null && refreshBackup.isNotEmpty) {
            await _secureStorage.writeRefreshToken(refreshBackup);
          }
        }
      }
      if (token == null || token.isEmpty) {
        if (cachedUser != null && cachedUser.role != UserRole.staffAdmin) {
          state = AuthState(
            status: AuthStatus.authenticated,
            currentUser: cachedUser,
          );
          return;
        }
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      // Keep existing session on app refresh/restart even if /auth/me is slow.
      if (cachedUser != null && cachedUser.role != UserRole.staffAdmin) {
        state = AuthState(
          status: AuthStatus.authenticated,
          currentUser: cachedUser,
        );
      }

      final user = await _authRepo.getMe().timeout(const Duration(seconds: 8));
      await _persistUser(user);
      state = AuthState(status: AuthStatus.authenticated, currentUser: user);
    } on TimeoutException {
      final cachedUser = _readCachedUser();
      state = cachedUser != null
          ? AuthState(status: AuthStatus.authenticated, currentUser: cachedUser)
          : const AuthState(status: AuthStatus.unauthenticated);
    } on AppException catch (appError) {
      if (appError.statusCode == 401 || appError.statusCode == 403) {
        await _clearLocalData();
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        final cachedUser = _readCachedUser();
        state = cachedUser != null
            ? AuthState(
                status: AuthStatus.authenticated, currentUser: cachedUser)
            : const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      final cachedUser = _readCachedUser();
      state = cachedUser != null
          ? AuthState(status: AuthStatus.authenticated, currentUser: cachedUser)
          : const AuthState(status: AuthStatus.unauthenticated);
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
      await _localStorage.setString(
        StorageKeys.accessTokenBackup,
        tokenResponse.accessToken,
      );
      await _localStorage.setString(
        StorageKeys.refreshTokenBackup,
        tokenResponse.refreshToken,
      );

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
    } on DioException catch (e) {
      final nested = e.error;
      final message = nested is AppException
          ? nested.message
          : (e.message?.trim().isNotEmpty ?? false)
              ? e.message!.trim()
              : 'An unexpected error occurred. Please try again.';
      state = AuthState(
        status: AuthStatus.error,
        error: message,
      );
    } catch (_) {
      state = const AuthState(
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
      // Best-effort — always clear local state regardless
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
    await _localStorage.setStringList(
        StorageKeys.userPermissions, user.permissions);
  }

  CurrentUser? _readCachedUser() {
    final raw = _localStorage.getString(StorageKeys.currentUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return CurrentUser.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLocalData() async {
    await _secureStorage.clearAll();
    await _localStorage.remove(StorageKeys.currentUser);
    await _localStorage.remove(StorageKeys.schoolId);
    await _localStorage.remove(StorageKeys.parentId);
    await _localStorage.remove(StorageKeys.userRole);
    await _localStorage.remove(StorageKeys.userPermissions);
    await _localStorage.remove(StorageKeys.selectedChildId);
    await _localStorage.remove(StorageKeys.accessTokenBackup);
    await _localStorage.remove(StorageKeys.refreshTokenBackup);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepo: ref.read(authRepositoryProvider),
    secureStorage: ref.read(secureStorageProvider),
    localStorage: ref.read(localStorageProvider),
  );
});

final currentUserProvider = Provider<CurrentUser?>((ref) {
  return ref.watch(authNotifierProvider).currentUser;
});
