import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/storage_service.dart';
// 192.168.1.2
class ApiClient {
  final String baseUrl =
      "http://192.168.1.19:8080/api/v1"; // Updated to match user configuration
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    print("Headers: $headers");
    print("Body: $body");
    print("URL: $baseUrl$path");
    return await http
        .post(
          Uri.parse("$baseUrl$path"),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> get(String path) async {
    final headers = await _getHeaders();
    print("Headers: $headers");
    print("URL: $baseUrl$path");
    return await http
        .get(Uri.parse("$baseUrl$path"), headers: headers)
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http
        .patch(
          Uri.parse("$baseUrl$path"),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http
        .put(
          Uri.parse("$baseUrl$path"),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> delete(String path) async {
    final headers = await _getHeaders();
    return await http
        .delete(Uri.parse("$baseUrl$path"), headers: headers)
        .timeout(const Duration(seconds: 10));
  }
}
