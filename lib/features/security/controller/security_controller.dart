import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final securityProvider =
    StateNotifierProvider<SecurityMobileController, AsyncValue<List<dynamic>>>((
      ref,
    ) {
      return SecurityMobileController(ApiClient());
    });

class SecurityMobileController
    extends StateNotifier<AsyncValue<List<dynamic>>> {
  final ApiClient _api;

  SecurityMobileController(this._api) : super(const AsyncValue.loading());

  Future<void> fetchTodayVisitors() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get("/security/visitors/today");
      if (response.statusCode == 200) {
        state = AsyncValue.data(jsonDecode(response.body));
      } else {
        state = AsyncValue.error(
          "Failed to fetch visitors",
          StackTrace.current,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> checkInVisitor(int visitorId) async {
    try {
      final response = await _api.post(
        "/security/visitors/$visitorId/check-in",
        {},
      );
      if (response.statusCode == 200) {
        fetchTodayVisitors();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> addWalkIn(Map<String, dynamic> data) async {
    try {
      final response = await _api.post("/security/visitors/walk-in", data);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> vehicleEntry(Map<String, dynamic> data) async {
    try {
      final response = await _api.post("/security/vehicles/entry", data);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> vehicleExit(String number) async {
    try {
      final response = await _api.post("/security/vehicles/$number/exit", {});
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<dynamic>> fetchTenants() async {
    try {
      final response = await _api.get("/common/tenants");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }
}
