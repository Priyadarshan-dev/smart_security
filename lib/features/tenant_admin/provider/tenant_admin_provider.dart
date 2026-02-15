import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../core/api/api_client.dart';
import '../model/tenant_admin_state.dart';
import '../service/tenant_admin_service.dart';

final tenantAdminServiceProvider = Provider(
  (ref) => TenantAdminService(ApiClient()),
);

final tenantAdminProvider =
    StateNotifierProvider<TenantAdminNotifier, TenantAdminState>((ref) {
      return TenantAdminNotifier(ref.watch(tenantAdminServiceProvider));
    });

class TenantAdminNotifier extends StateNotifier<TenantAdminState> {
  final TenantAdminService _service;
  final _logger = Logger();

  TenantAdminNotifier(this._service) : super(TenantAdminState.initial());

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
      final response = await _service.getPendingApprovals();
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
      final response = await _service.getTodayVisitors();
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
      final response = await _service.getAllVisitors();
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
      _logger.i(
        'Approving/rejecting visitorId: $visitorId with status: $status and remarks: $remarks',
      );

      final response = await _service.approveOrReject(visitorId, {
        "status": status,
        "remarks": remarks,
      });

      _logger.i('Response status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Update pendingApprovals locally
        final approvals = state.pendingApprovals.value;
        if (approvals != null) {
          final updatedApprovals =
              approvals.where((v) => v['id'] != visitorId).toList();
          state = state.copyWith(
            pendingApprovals: AsyncValue.data(updatedApprovals),
          );
        }

        // Also update other lists if they contain the visitor
        final today = state.todayVisitors.value;
        if (today != null) {
          final updatedToday =
              today.map((v) {
                if (v['id'] == visitorId) {
                  return <String, dynamic>{
                    ...v as Map<String, dynamic>,
                    'status': status,
                    'remarks': remarks,
                  };
                }
                return v;
              }).toList();
          state = state.copyWith(todayVisitors: AsyncValue.data(updatedToday));
        }

        final all = state.allVisitors.value;
        if (all != null) {
          final updatedAll =
              all.map((v) {
                if (v['id'] == visitorId) {
                  return <String, dynamic>{
                    ...v as Map<String, dynamic>,
                    'status': status,
                    'remarks': remarks,
                  };
                }
                return v;
              }).toList();
          state = state.copyWith(allVisitors: AsyncValue.data(updatedAll));
        }

        _logger.i('Operation successful');
        return true;
      } else {
        _logger.w('Operation failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Exception while approving/rejecting visitor');
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> scheduleVisitor(Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _service.scheduleVisitor(data);
      if (response.statusCode == 200) {
        await fetchDashboardData();
        return true;
      }
    } catch (e) {
      print(e);
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> updateVisitor(int visitorId, Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      print(data);
      final response = await _service.updateVisitor(visitorId, data);
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final today = state.todayVisitors.value;
        if (today != null) {
          final updatedToday =
              today.map((v) {
                if (v['id'] == visitorId)
                  return <String, dynamic>{
                    ...v as Map<String, dynamic>,
                    ...responseData as Map<String, dynamic>,
                  };
                return v;
              }).toList();
          state = state.copyWith(todayVisitors: AsyncValue.data(updatedToday));
        }

        final all = state.allVisitors.value;
        if (all != null) {
          final updatedAll =
              all.map((v) {
                if (v['id'] == visitorId)
                  return <String, dynamic>{
                    ...v as Map<String, dynamic>,
                    ...responseData as Map<String, dynamic>,
                  };
                return v;
              }).toList();
          state = state.copyWith(allVisitors: AsyncValue.data(updatedAll));
        }

        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> deleteVisitor(int visitorId) async {
    _logger.i("Delete Visitor Called");
    _logger.i("Visitor ID: $visitorId");

    state = state.copyWith(isOperationLoading: true);

    try {
      final response = await _service.deleteVisitor(visitorId);

      _logger.i("Delete API Status Code: ${response.statusCode}");
      _logger.i("Delete API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        _logger.i("Visitor deleted successfully");

        final today = state.todayVisitors.value;
        if (today != null) {
          final updatedToday =
              today.where((v) => v['id'] != visitorId).toList();
          state = state.copyWith(todayVisitors: AsyncValue.data(updatedToday));
        }

        final all = state.allVisitors.value;
        if (all != null) {
          final updatedAll = all.where((v) => v['id'] != visitorId).toList();
          state = state.copyWith(allVisitors: AsyncValue.data(updatedAll));
        }

        final approvals = state.pendingApprovals.value;
        if (approvals != null) {
          final updatedApprovals =
              approvals.where((v) => v['id'] != visitorId).toList();
          state = state.copyWith(
            pendingApprovals: AsyncValue.data(updatedApprovals),
          );
        }

        return true;
      } else {
        _logger.e("Delete failed with status ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      _logger.e("Delete Exception Occurred", error: e, stackTrace: stackTrace);
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }

    return false;
  }

  Future<void> fetchTenantVehicles() async {
    state = state.copyWith(vehicles: const AsyncValue.loading());
    try {
      final response = await _service.getTenantVehicles();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        state = state.copyWith(vehicles: AsyncValue.data(decoded));
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

  Future<bool> addVehicle(Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _service.addVehicle(data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTenantVehicles();
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _service.updateVehicle(id, data);
      if (response.statusCode == 200) {
        final currentVehicles = state.vehicles.value;
        if (currentVehicles != null) {
          final updatedVehicles =
              currentVehicles.map((v) {
                if (v['id'] == id) {
                  final responseData =
                      response.body.isNotEmpty
                          ? jsonDecode(response.body) as Map<String, dynamic>
                          : data;
                  return <String, dynamic>{
                    ...v as Map<String, dynamic>,
                    ...responseData,
                  };
                }
                return v;
              }).toList();
          state = state.copyWith(vehicles: AsyncValue.data(updatedVehicles));
        }
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
      final response = await _service.deleteVehicle(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        final currentVehicles = state.vehicles.value;
        if (currentVehicles != null) {
          final updatedVehicles =
              currentVehicles.where((v) => v['id'] != id).toList();
          state = state.copyWith(vehicles: AsyncValue.data(updatedVehicles));
        }
        return true;
      }
    } catch (_) {
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }
}
