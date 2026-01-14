import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final tenantAdminProvider =
    StateNotifierProvider<TenantAdminController, TenantAdminState>((ref) {
      return TenantAdminController(ApiClient());
    });

class TenantAdminState {
  final AsyncValue<List<dynamic>> pendingApprovals;
  final AsyncValue<List<dynamic>> todayVisitors;
  final AsyncValue<List<dynamic>> allVisitors;
  final AsyncValue<List<dynamic>> vehicles;
  final bool isOperationLoading;

  TenantAdminState({
    required this.pendingApprovals,
    required this.todayVisitors,
    required this.allVisitors,
    required this.vehicles,
    this.isOperationLoading = false,
  });

  TenantAdminState copyWith({
    AsyncValue<List<dynamic>>? pendingApprovals,
    AsyncValue<List<dynamic>>? todayVisitors,
    AsyncValue<List<dynamic>>? allVisitors,
    AsyncValue<List<dynamic>>? vehicles,
    bool? isOperationLoading,
  }) {
    return TenantAdminState(
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      todayVisitors: todayVisitors ?? this.todayVisitors,
      allVisitors: allVisitors ?? this.allVisitors,
      vehicles: vehicles ?? this.vehicles,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
    );
  }
}

class TenantAdminController extends StateNotifier<TenantAdminState> {
  final ApiClient _api;

  TenantAdminController(this._api)
    : super(
        TenantAdminState(
          pendingApprovals: const AsyncValue.loading(),
          todayVisitors: const AsyncValue.loading(),
          allVisitors: const AsyncValue.loading(),
          vehicles: const AsyncValue.loading(),
        ),
      );

  Future<void> fetchDashboardData() async {
    await Future.wait([
      fetchPendingApprovals(),
      fetchTodayVisitors(),
      fetchAllVisitors(),
      fetchTenantVehicles(),
    ]);
  }

  Future<void> fetchPendingApprovals() async {
    state = state.copyWith(pendingApprovals: const AsyncValue.loading());
    try {
      final response = await _api.get("/tenant-admin/approvals/pending");
      if (response.statusCode == 200) {
        state = state.copyWith(
          pendingApprovals: AsyncValue.data(jsonDecode(response.body)),
        );
      } else {
        state = state.copyWith(
          pendingApprovals: AsyncValue.error(
            "Failed to fetch approvals",
            StackTrace.current,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        pendingApprovals: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  Future<void> fetchTodayVisitors() async {
    state = state.copyWith(todayVisitors: const AsyncValue.loading());
    try {
      final response = await _api.get("/tenant-admin/visitors/today");
      if (response.statusCode == 200) {
        state = state.copyWith(
          todayVisitors: AsyncValue.data(jsonDecode(response.body)),
        );
      } else {
        state = state.copyWith(
          todayVisitors: AsyncValue.error(
            "Failed to fetch today's visitors",
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

  Future<void> fetchAllVisitors() async {
    state = state.copyWith(allVisitors: const AsyncValue.loading());
    try {
      final response = await _api.get("/tenant-admin/visitors");
      print("response");
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        state = state.copyWith(
          allVisitors: AsyncValue.data(jsonDecode(response.body)),
        );
      } else {
        state = state.copyWith(
          allVisitors: AsyncValue.error(
            "Failed to fetch visitors",
            StackTrace.current,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        allVisitors: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  Future<bool> approveOrReject(
    int visitorId,
    String status,
    String remarks,
  ) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.patch("/tenant-admin/approvals/$visitorId", {
        "status": status,
        "remarks": remarks,
      });
      if (response.statusCode == 200) {
        await fetchDashboardData();
        return true;
      }
    } catch (_) {} finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> scheduleVisitor(Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post("/tenant-admin/visitors/schedule", data);
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        await fetchDashboardData();
        return true;
      }
    } catch (_) {} finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> updateVisitor(int visitorId, Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.put(
        "/tenant-admin/visitors/$visitorId",
        data,
      );
      if (response.statusCode == 200) {
        await fetchDashboardData();
        return true;
      }
    } catch (_) {} finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> deleteVisitor(int visitorId) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.delete("/tenant-admin/visitors/$visitorId");
      if (response.statusCode == 200) {
        await fetchDashboardData();
        return true;
      }
    } catch (_) {} finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<void> fetchTenantVehicles() async {
    state = state.copyWith(vehicles: const AsyncValue.loading());
    try {
      final response = await _api.get("/tenant-admin/vehicles");
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
      state = state.copyWith(
        vehicles: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  Future<bool> addVehicle(Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _api.post("/tenant-admin/vehicles", data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTenantVehicles();
        return true;
      }
    } catch (_) {} finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }
}
