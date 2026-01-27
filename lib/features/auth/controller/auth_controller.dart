import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ApiClient(), StorageService());
});

class AuthController extends StateNotifier<AuthState> {
  final ApiClient _api;
  final StorageService _storage;

  AuthController(this._api, this._storage) : super(AuthState.initial());

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _api.post("/auth/login", {
        "email": email,
        "password": password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Login Response: $data"); // Debug log using print as requested
        await _storage.saveToken(data['token']);
        await _storage.saveRole(data['role']);

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
      print("Login Error: $e");
      String message = "Server unreachable. Please check your connection.";
      if (e.toString().contains("TimeoutException")) {
        message = "Connection timeout. Server might be slow or down.";
      }
      state = state.copyWith(status: AuthStatus.error, error: message);
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> checkAuth() async {
    final token = await _storage.getToken();
    final role = await _storage.getRole();
    if (token != null && role != null) {
      state = state.copyWith(status: AuthStatus.authenticated, role: role);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> syncFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token == null) {
        print("FCM Token is null, skipping sync.");
        return;
      }

      final lastSyncedToken = await _storage.getLastFcmToken();
      if (token == lastSyncedToken) {
        print("FCM Token is already synced.");
        return;
      }

      print("Syncing FCM Token: $token");
      final response = await _api.post("/auth/save-fcm-token", {
        "fcmToken": token,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.saveLastFcmToken(token);
        print("FCM Token synced successfully.");
      } else {
        print(
          "Failed to sync FCM Token: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      print("Error syncing FCM Token: $e");
    }
  }
}
