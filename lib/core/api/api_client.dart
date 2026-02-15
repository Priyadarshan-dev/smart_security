import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/storage_service.dart';

class ApiClient {
  final String baseUrl1 = "http://13.205.93.213:8080/api/v1";

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    http.Response response = await request();

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();

      if (refreshed) {
        response = await request();
      } else {
        throw Exception("Session expired. Please logout and login again.");
      }
    }

    return response;
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();

    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl1/auth/refresh-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final newAccessToken = data["accessToken"];
        final newRefreshToken = data["refreshToken"];

        await _storage.saveToken(newAccessToken);
        await _storage.saveRefreshToken(newRefreshToken);

        return true;
      } else {
        throw Exception("Session expired. Please logout and login again.");
      }
    } catch (e) {
      throw Exception("Session expired. Please logout and login again.");
    }
  }

  Future<http.Response> get(String path) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http
          .get(Uri.parse("$baseUrl1$path"), headers: headers)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      print("Headers: $headers");
      print("Body: $body");
      print("URL: $baseUrl1$path");

      return await http
          .post(
            Uri.parse("$baseUrl1$path"),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http
          .patch(
            Uri.parse("$baseUrl1$path"),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http
          .put(
            Uri.parse("$baseUrl1$path"),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> delete(String path) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http
          .delete(Uri.parse("$baseUrl1$path"), headers: headers)
          .timeout(const Duration(seconds: 10));
    });
  }
}
