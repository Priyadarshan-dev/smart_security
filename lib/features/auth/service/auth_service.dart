import 'package:ceedeeyes/core/api/api_client.dart';
import 'package:ceedeeyes/core/storage/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final ApiClient _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  Future<http.Response> login(String email, String password) async {
    return await _api.post("/auth/login", {
      "email": email,
      "password": password,
    });
  }

  //http://192.168.1.36:8080/api/v1/auth/refresh-token


  Future<void> saveSession(String token, String role,String refreshToken) async {
    await _storage.saveToken(token);
    await _storage.saveRole(role);
    await _storage.saveRefreshToken(refreshToken);
  }

  Future<void> clearSession() async {
    await _storage.clear();
  }

  Future<Map<String, String?>> getSession() async {
    final token = await _storage.getToken();
    final role = await _storage.getRole();
    return {'accessToken': token, 'role': role};
  }

  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  Future<String?> getLastSyncedFcmToken() async {
    return await _storage.getLastFcmToken();
  }

  Future<http.Response> syncFcmToken(String token) async {
    return await _api.post("/auth/save-fcm-token", {"fcmToken": token});
  }

  Future<void> saveLastFcmToken(String token) async {
    await _storage.saveLastFcmToken(token);
  }
}
