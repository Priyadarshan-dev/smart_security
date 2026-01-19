import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final securityProvider =
    StateNotifierProvider<SecurityMobileController, SecurityState>((ref) {
      return SecurityMobileController(ApiClient());
    });

class SecurityState {
  final AsyncValue<List<dynamic>> todayVisitors;
  final List<dynamic> tenants;
  final List<dynamic> tenantAdmins;
  final AsyncValue<List<dynamic>> vehicles;
  final bool isOperationLoading;

  SecurityState({
    required this.todayVisitors,
    this.tenants = const [],
    this.tenantAdmins = const [],
    required this.vehicles,
    this.isOperationLoading = false,
  });

  SecurityState copyWith({
    AsyncValue<List<dynamic>>? todayVisitors,
    List<dynamic>? tenants,
    List<dynamic>? tenantAdmins,
    AsyncValue<List<dynamic>>? vehicles,
    bool? isOperationLoading,
  }) {
    return SecurityState(
      todayVisitors: todayVisitors ?? this.todayVisitors,
      tenants: tenants ?? this.tenants,
      tenantAdmins: tenantAdmins ?? this.tenantAdmins,
      vehicles: vehicles ?? this.vehicles,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
    );
  }
}

class SecurityMobileController extends StateNotifier<SecurityState> {
  final ApiClient _api;

  SecurityMobileController(this._api)
    : super(
        SecurityState(
          todayVisitors: const AsyncValue.loading(),
          vehicles: const AsyncValue.loading(),
        ),
      );

  Future<void> fetchTodayVisitors() async {
    state = state.copyWith(todayVisitors: const AsyncValue.loading());
    try {
      final response = await _api.get("/security/visitors/today");
      if (response.statusCode == 200) {
        state = state.copyWith(
          todayVisitors: AsyncValue.data(jsonDecode(response.body)),
        );
      } else {
        state = state.copyWith(
          todayVisitors: AsyncValue.error(
            "Failed to fetch visitors",
            StackTrace.current,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        todayVisitors: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  Future<bool> checkInVisitor(int visitorId) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post(
        "/security/visitors/$visitorId/check-in",
        {},
      );
      if (response.statusCode == 200) {
        await fetchTodayVisitors();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> checkOutVisitor(int visitorId) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post(
        "/security/visitors/$visitorId/check-out",
        {},
      );
      if (response.statusCode == 200) {
        await fetchTodayVisitors();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> addWalkIn(Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post("/security/visitors/walk-in", data);
      print(data);
      print("Walk-in Status: ${response.statusCode}");
      print("Walk-in Data: ${data['assignedAdmins']}");
      print("Walk-in Body: ${response.body}");
      return response.statusCode == 200;
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> vehicleEntry(Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post("/security/vehicles/entry", data);
      print("Vehicle Entry Status: ${response.statusCode}");
      print("Vehicle Entry Body: ${response.body}");
      if (response.statusCode == 200) {
        await fetchVehicles();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> vehicleExit(int id) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post("/security/vehicles/$id/exit", {});
      if (response.statusCode == 200) {
        await fetchVehicles();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> vehicleCheckIn(int id) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post("/security/vehicles/$id/check-in", {});
      print("Vehicle Check-in Status: ${response.statusCode}");
      print("Vehicle Check-in Body: ${response.body}");
      if (response.statusCode == 200) {
        await fetchVehicles();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<void> fetchTenants() async {
    try {
      // Reverting to /common/tenants because /super-admin/tenants gives 403 Forbidden for Security users
      final response = await _api.get("/security/tenants");
      print("Fetch /common/tenants Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Tenants Data Loaded: ${data.length} items");
        state = state.copyWith(tenants: data);
      } else {
        print(
          "Fetch Tenants Failed: Status ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      print("Fetch Tenants Error: $e");
    }
  }

  Future<void> fetchVehicles() async {
    state = state.copyWith(vehicles: const AsyncValue.loading());
    try {
      final response = await _api.get("/security/vehicles");
      if (response.statusCode == 200) {
        state = state.copyWith(
          vehicles: AsyncValue.data(jsonDecode(response.body)),
        );
      } else {
        state = state.copyWith(
          vehicles: AsyncValue.error(
            "Failed to fetch vehicles",
            StackTrace.current,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(vehicles: AsyncValue.error(e, StackTrace.current));
    }
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.put("/security/vehicles/$id", data);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchVehicles();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> deleteVehicle(int id) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.delete("/security/vehicles/$id");
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchVehicles();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<void> refreshDashboard() async {
    try {
      await Future.wait([
        fetchTenants(),
        fetchTodayVisitors(),
        fetchVehicles(),
      ]);
    } catch (_) {}
  }

  void clearTenantAdmins() {
    state = state.copyWith(tenantAdmins: []);
  }
}
