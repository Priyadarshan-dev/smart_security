import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../model/auth_state.dart';
import '../service/auth_service.dart';

final authServiceProvider = Provider(
  (ref) => AuthService(ApiClient(), StorageService()),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    _listenToSessionExpiry();
  }

  void _listenToSessionExpiry() {
    ApiClient.sessionExpiryStream.listen((_) {
      logout();
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _authService.login(email, password);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _authService.saveSession(
          data['accessToken'],
          data['role'],
          data['refreshToken'],
        );

        // await _authService.refreshToken();

        state = state.copyWith(
          status: AuthStatus.authenticated,
          role: data['role'],
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        state = state.copyWith(
          status: AuthStatus.error,
          error: "Invalid email or password",
        );
      } else {
        String errorMessage = "Login failed";
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['error'] ?? data['message'] ?? errorMessage;
        } catch (_) {}
        state = state.copyWith(status: AuthStatus.error, error: errorMessage);
      }
    } catch (e) {
      String message = "Server unreachable. Please check your connection.";
      if (e.toString().contains("TimeoutException")) {
        message = "Connection timeout. Server might be slow or down.";
      }
      state = state.copyWith(status: AuthStatus.error, error: message);
    }
  }

  Future<void> logout() async {
    await _authService.clearSession();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> checkAuth() async {
    final session = await _authService.getSession();
    if (session['accessToken'] != null && session['role'] != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: session['role'],
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> syncFcmToken() async {
    try {
      final token = await _authService.getFcmToken();

      if (token == null) {
        return;
      }

      final lastSyncedToken = await _authService.getLastSyncedFcmToken();
      if (token == lastSyncedToken) {
        return;
      }

      final response = await _authService.syncFcmToken(token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _authService.saveLastFcmToken(token);
      } else {}
    } catch (e) {}
  }
}
