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

  TenantAdminState({
    required this.pendingApprovals,
    required this.todayVisitors,
  });

  TenantAdminState copyWith({
    AsyncValue<List<dynamic>>? pendingApprovals,
    AsyncValue<List<dynamic>>? todayVisitors,
  }) {
    return TenantAdminState(
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      todayVisitors: todayVisitors ?? this.todayVisitors,
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
        ),
      );

  Future<void> fetchDashboardData() async {
    await Future.wait([fetchPendingApprovals(), fetchTodayVisitors()]);
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

  Future<bool> approveOrReject(
    int visitorId,
    String status,
    String remarks,
  ) async {
    try {
      final response = await _api.patch("/tenant-admin/approvals/$visitorId", {
        "status": status,
        "remarks": remarks,
      });
      if (response.statusCode == 200) {
        fetchDashboardData();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> scheduleVisitor(Map<String, dynamic> data) async {
    try {
      final response = await _api.post("/tenant-admin/visitors/schedule", data);
      if (response.statusCode == 200) {
        fetchDashboardData();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
