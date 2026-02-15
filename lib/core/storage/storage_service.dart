import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveRefreshToken(String token)async{
    await _storage.write(key: 'refresh_token', value: token );
  }

  Future<String?> getRefreshToken()async{
   return await _storage.read(key: 'refresh_token');
  }


  Future<void> saveRole(String role) async {
    await _storage.write(key: 'role', value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }

  Future<void> saveLastFcmToken(String token) async {
    await _storage.write(key: 'last_fcm_token', value: token);
  }

  Future<String?> getLastFcmToken() async {
    return await _storage.read(key: 'last_fcm_token');
  }

  Future<void> saveCompanyName(String companyName) async {
    await _storage.write(key: 'company_name', value: companyName);
  }

  Future<String?> getCompanyName() async {
    return await _storage.read(key: 'company_name');
  }
}
