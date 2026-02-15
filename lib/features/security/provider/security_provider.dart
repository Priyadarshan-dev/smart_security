import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/api/api_client.dart';
import '../model/security_state.dart';
import '../model/staff_model.dart';
import '../service/security_service.dart';

final securityServiceProvider = Provider((ref) => SecurityService(ApiClient()));

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>(
  (ref) {
    return SecurityNotifier(ref.watch(securityServiceProvider));
  },
);

class SecurityNotifier extends StateNotifier<SecurityState> {
  final SecurityService _service;
  final Logger _logger = Logger();

  SecurityNotifier(this._service) : super(SecurityState.initial());

  Future<void> fetchTodayVisitors() async {
    state = state.copyWith(todayVisitors: const AsyncValue.loading());
    try {
      final response = await _service.getTodayVisitors();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List ? decoded : [];
        state = state.copyWith(todayVisitors: AsyncValue.data(list));
      } else {
        state = state.copyWith(todayVisitors: const AsyncValue.data([]));
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
      final response = await _service.checkInVisitor(visitorId);
      if (response.statusCode == 200) {
        final visitors = state.todayVisitors.value;
        if (visitors != null) {
          final updatedVisitors =
              visitors.map((v) {
                if (v['id'] == visitorId) {
                  final responseData = jsonDecode(response.body);
                  return {
                    ...v,
                    'status': responseData['status'] ?? 'CHECKED_IN',
                    'checkInTime': responseData['checkInTime'],
                  };
                }
                return v;
              }).toList();
          state = state.copyWith(
            todayVisitors: AsyncValue.data(updatedVisitors),
          );
        }
        print("Success while Check-In -- Print Statement");
        return true;
      }
    } catch (error) {
      print("Error while Check-In $error -- Print Statement");
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<bool> checkOutVisitor(int visitorId) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _service.checkOutVisitor(visitorId);
      if (response.statusCode == 200) {
        final visitors = state.todayVisitors.value;
        if (visitors != null) {
          final updatedVisitors =
              visitors.map((v) {
                if (v['id'] == visitorId) {
                  final responseData = jsonDecode(response.body);
                  return {
                    ...v,
                    'status': responseData['status'] ?? 'CHECKED_OUT',
                    'checkOutTime': responseData['checkOutTime'],
                  };
                }
                return v;
              }).toList();
          state = state.copyWith(
            todayVisitors: AsyncValue.data(updatedVisitors),
          );
        }
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
      // Clone data for safe logging
      final safeLogData = Map<String, dynamic>.from(data);

      if (safeLogData["imageUrl"] != null) {
        safeLogData["imageUrl"] =
            "[BASE64_IMAGE_${data["imageUrl"].length}_chars]";
      }

      if (safeLogData["attachment"] != null &&
          safeLogData["attachment"].toString().isNotEmpty) {
        safeLogData["attachment"] =
            "[BASE64_ATTACHMENT_${data["attachment"].length}_chars]";
      }

      _logger.d("🚀 Sending Walk-in POST request");
      _logger.d("📦 Request Body: ${jsonEncode(safeLogData)}");

      final response = await _service.addWalkIn(data);

      _logger.d("📨 Response Status: ${response.statusCode}");
      _logger.d("📨 Response Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      _logger.e(
        "🔥 Error while adding walk-in",
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
  }

  Future<bool> vehicleEntry(Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _service.vehicleEntry(data);
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
      final response = await _service.vehicleExit(id);
      if (response.statusCode == 200) {
        final currentVehicles = state.vehicles.value;
        if (currentVehicles != null) {
          final updatedVehicles =
              currentVehicles.map((v) {
                if (v['id'] == id) {
                  final responseData = jsonDecode(response.body);
                  return {
                    ...v,
                    'status': responseData['status'] ?? 'EXITED',
                    'exitTime': responseData['exitTime'],
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

  Future<bool> vehicleCheckIn(int id) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _service.vehicleCheckIn(id);
      print("Vehicle Check-in Status: ${response.statusCode}");
      print("Vehicle Check-in Body: ${response.body}");
      if (response.statusCode == 200) {
        final currentVehicles = state.vehicles.value;
        if (currentVehicles != null) {
          final updatedVehicles =
              currentVehicles.map((v) {
                if (v['id'] == id) {
                  final responseData = jsonDecode(response.body);
                  return {
                    ...v,
                    'status': responseData['status'] ?? 'CHECKED_IN',
                    'checkInTime': responseData['checkInTime'],
                  };
                }
                return v;
              }).toList();
          state = state.copyWith(vehicles: AsyncValue.data(updatedVehicles));
        }
        print("Success while Vehicle Check-In -- Print Statement");
        return true;
      }
    } catch (error) {
      print("Error while Vehicle Check-In $error -- Print Statement");
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }
    return false;
  }

  Future<void> fetchTenants() async {
    try {
      final response = await _service.getTenants();
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
      final response = await _service.getVehicles();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List ? decoded : [];
        state = state.copyWith(vehicles: AsyncValue.data(list));
      } else {
        state = state.copyWith(vehicles: const AsyncValue.data([]));
      }
    } catch (e) {
      state = state.copyWith(vehicles: AsyncValue.error(e, StackTrace.current));
    }
  }

  // ------------------------------------staffs Section------------------------
  Future<void> fetchStaffs() async {
    _logger.i("Fetching staffs started");

    state = state.copyWith(isStaffLoading: true, staffError: null);

    try {
      final response = await _service.getStaffs();

      _logger.d("Status Code: ${response.statusCode}");
      _logger.v("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List ? decoded : [];

        final staffList = list.map((e) => StaffModel.fromJson(e)).toList();

        _logger.i("Fetched ${staffList.length} staffs successfully");

        state = state.copyWith(
          staffs: staffList,
          isStaffLoading: false,
          status: SecurityStatus.success,
        );
      } else {
        _logger.e("Failed to fetch staffs. Status: ${response.statusCode}");

        state = state.copyWith(
          isStaffLoading: false,
          staffError: "Failed to fetch staffs",
          status: SecurityStatus.failure,
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        "Exception while fetching staffs",
        error: e,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isStaffLoading: false,
        staffError: e.toString(),
        status: SecurityStatus.failure,
      );
    }
  }

  // Future<bool> staffCheckIn(int id) async {
  //   state = state.copyWith(isOperationLoading: true);
  //   try {
  //     final response = await _service.staffCheckIn(id);
  //     if (response.statusCode == 200) {
  //       await fetchStaffs();
  //       return true;
  //     }
  //   } catch (error) {
  //     print("Error while Staff Check-In $error");
  //   } finally {
  //     state = state.copyWith(isOperationLoading: false);
  //   }
  //   return false;
  // }

  Future<bool> staffCheckIn(int id) async {
    state = state.copyWith(isOperationLoading: true);

    try {
      final response = await _service.staffCheckIn(id);

      if (response.statusCode == 200) {
        // 🔥 Update locally instead of calling fetchStaffs()
        final updatedStaffs =
            state.staffs.map((staff) {
              if (staff.id == id) {
                return staff.copyWith(status: 'CHECKED_IN');
              }
              return staff;
            }).toList();

        state = state.copyWith(
          staffs: updatedStaffs,
          status: SecurityStatus.success,
        );

        return true;
      }
    } catch (error) {
      print("Error while Staff Check-In $error");
      state = state.copyWith(status: SecurityStatus.failure);
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }

    return false;
  }

  // Future<bool> staffCheckOut(int id) async {
  //   state = state.copyWith(isOperationLoading: true);
  //   try {
  //     final response = await _service.staffCheckOut(id);
  //     if (response.statusCode == 200) {
  //       await fetchStaffs();
  //       return true;
  //     }
  //   } catch (error) {
  //     print("Error while Staff Check-Out $error");
  //   } finally {
  //     state = state.copyWith(isOperationLoading: false);
  //   }
  //   return false;
  // }
  Future<bool> staffCheckOut(int id) async {
    state = state.copyWith(isOperationLoading: true);

    try {
      final response = await _service.staffCheckOut(id);

      if (response.statusCode == 200) {
        // 🔥 Update locally instead of calling fetchStaffs()
        final updatedStaffs =
            state.staffs.map((staff) {
              if (staff.id == id) {
                return staff.copyWith(status: 'CHECKED_OUT');
              }
              return staff;
            }).toList();

        state = state.copyWith(
          staffs: updatedStaffs,
          status: SecurityStatus.success,
        );

        return true;
      }
    } catch (error) {
      print("Error while Staff Check-Out $error");
      state = state.copyWith(status: SecurityStatus.failure);
    } finally {
      state = state.copyWith(isOperationLoading: false);
    }

    return false;
  }

  Future<void> fetchStaffReports(
    DateTime start,
    DateTime end, {
    bool isLoadMore = false,
  }) async {
    if (isLoadMore &&
        (!state.hasMoreStaffs || state.status == SecurityStatus.loading)) {
      return;
    }

    if (!isLoadMore) {
      state = state.copyWith(
        staffReports: const AsyncValue.loading(),
        staffReportsPage: 0,
        hasMoreStaffs: true,
        status: SecurityStatus.loading,
      );
    } else {
      state = state.copyWith(status: SecurityStatus.loading);
    }

    try {
      final startDate = start.toIso8601String().split('T')[0];
      final endDate = end.toIso8601String().split('T')[0];
      final currentPage = isLoadMore ? state.staffReportsPage + 1 : 0;
      final size = 10;
      final response = await _service.getStaffHistory(
        startDate,
        endDate,
        currentPage,
        size,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> newList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('content')) {
          newList = decoded['content'];
        } else if (decoded is List) {
          newList = decoded;
        }

        final currentList = isLoadMore ? (state.staffReports.value ?? []) : [];
        final updatedList = [...currentList, ...newList];

        state = state.copyWith(
          staffReports: AsyncValue.data(updatedList),
          staffReportsPage: currentPage,
          hasMoreStaffs: newList.length >= size,
          status: SecurityStatus.success,
        );
      } else {
        state = state.copyWith(
          status: SecurityStatus.failure,
          staffReports:
              isLoadMore
                  ? state.staffReports
                  : AsyncValue.error(
                    "Failed to fetch staff reports",
                    StackTrace.current,
                  ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SecurityStatus.failure,
        staffReports:
            isLoadMore
                ? state.staffReports
                : AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  // Future<void> fetchStaffReports(
  //   DateTime start,
  //   DateTime end, {
  //   bool isLoadMore = false,
  // }) async {
  //   if (isLoadMore &&
  //       (!state.hasMoreVehicles || state.status == SecurityStatus.loading)) {
  //     return;
  //   }
  //   if (!isLoadMore) {
  //     state = state.copyWith(
  //       vehicleReports: const AsyncValue.loading(),
  //       vehicleReportsPage: 0,
  //       hasMoreVehicles: true,
  //       status: SecurityStatus.loading,
  //     );
  //   } else {
  //     state = state.copyWith(status: SecurityStatus.loading);
  //   }
  // }

  /*  Future<void> fetchVehicleReports(
    DateTime start,
    DateTime end, {
    bool isLoadMore = false,
  }) async {
    if (isLoadMore &&
        (!state.hasMoreVehicles || state.status == SecurityStatus.loading)) {
      return;
    }

    if (!isLoadMore) {
      state = state.copyWith(
        vehicleReports: const AsyncValue.loading(),
        vehicleReportsPage: 0,
        hasMoreVehicles: true,
        status: SecurityStatus.loading,
      );
    } else {
      state = state.copyWith(status: SecurityStatus.loading);
    }

    try {
      final startDate = start.toIso8601String().split('T')[0];
      final endDate = end.toIso8601String().split('T')[0];
      final currentPage = isLoadMore ? state.vehicleReportsPage + 1 : 0;
      final size = 10;
      final response = await _service.getVehicleHistory(
        startDate,
        endDate,
        currentPage,
        size,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("Vehicle Reports Data: $decoded");
        List<dynamic> newList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('content')) {
          newList = decoded['content'];
        } else if (decoded is List) {
          newList = decoded;
        }

        final currentList =
            isLoadMore ? (state.vehicleReports.value ?? []) : [];
        final updatedList = [...currentList, ...newList];

        state = state.copyWith(
          vehicleReports: AsyncValue.data(updatedList),
          vehicleReportsPage: currentPage,
          hasMoreVehicles: newList.length >= size,
          status: SecurityStatus.success,
        );
      } else {
        state = state.copyWith(
          status: SecurityStatus.failure,
          vehicleReports:
              isLoadMore
                  ? state.vehicleReports
                  : AsyncValue.error(
                    "Failed to fetch vehicle reports",
                    StackTrace.current,
                  ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SecurityStatus.failure,
        vehicleReports:
            isLoadMore
                ? state.vehicleReports
                : AsyncValue.error(e, StackTrace.current),
      );
    }
  }
  *
  * */
  // Future<>
  // ------------------------------End--------------------------------

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isOperationLoading: true);
    try {
      final response = await _service.updateVehicle(id, data);
      if (response.statusCode == 200 || response.statusCode == 204) {
        final currentVehicles = state.vehicles.value;
        if (currentVehicles != null) {
          final updatedVehicles =
              currentVehicles.map((v) {
                if (v['id'] == id) {
                  // If 204 No Content, use requested data; if 200, use response body if available
                  final Map<String, dynamic> updatedData =
                      response.statusCode == 200 && response.body.isNotEmpty
                          ? jsonDecode(response.body)
                          : data;
                  return {...v, ...updatedData};
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

  Future<void> fetchVisitorReports(
    DateTime start,
    DateTime end, {
    bool isLoadMore = false,
  }) async {
    if (isLoadMore &&
        (!state.hasMoreVisitors || state.status == SecurityStatus.loading)) {
      return;
    }

    if (!isLoadMore) {
      state = state.copyWith(
        visitorReports: const AsyncValue.loading(),
        visitorReportsPage: 0,
        hasMoreVisitors: true,
        status: SecurityStatus.loading,
      );
    } else {
      state = state.copyWith(status: SecurityStatus.loading);
    }

    try {
      final startDate = start.toIso8601String().split('T')[0];
      final endDate = end.toIso8601String().split('T')[0];
      final currentPage = isLoadMore ? state.visitorReportsPage + 1 : 0;
      final size = 10;
      final response = await _service.getVisitorHistory(
        startDate,
        endDate,
        currentPage,
        size,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("Visitor Reports Data: $decoded");
        List<dynamic> newList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('content')) {
          newList = decoded['content'];
        } else if (decoded is List) {
          newList = decoded;
        }

        final currentList =
            isLoadMore ? (state.visitorReports.value ?? []) : [];
        final updatedList = [...currentList, ...newList];

        state = state.copyWith(
          visitorReports: AsyncValue.data(updatedList),
          visitorReportsPage: currentPage,
          hasMoreVisitors: newList.length >= size,
          status: SecurityStatus.success,
        );
      } else {
        state = state.copyWith(
          status: SecurityStatus.failure,
          visitorReports:
              isLoadMore
                  ? state.visitorReports
                  : AsyncValue.error(
                    "Failed to fetch visitor reports",
                    StackTrace.current,
                  ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SecurityStatus.failure,
        visitorReports:
            isLoadMore
                ? state.visitorReports
                : AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  Future<void> fetchVehicleReports(
    DateTime start,
    DateTime end, {
    bool isLoadMore = false,
  }) async {
    if (isLoadMore &&
        (!state.hasMoreVehicles || state.status == SecurityStatus.loading)) {
      return;
    }

    if (!isLoadMore) {
      state = state.copyWith(
        vehicleReports: const AsyncValue.loading(),
        vehicleReportsPage: 0,
        hasMoreVehicles: true,
        status: SecurityStatus.loading,
      );
    } else {
      state = state.copyWith(status: SecurityStatus.loading);
    }

    try {
      final startDate = start.toIso8601String().split('T')[0];
      final endDate = end.toIso8601String().split('T')[0];
      final currentPage = isLoadMore ? state.vehicleReportsPage + 1 : 0;
      final size = 10;
      final response = await _service.getVehicleHistory(
        startDate,
        endDate,
        currentPage,
        size,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("Vehicle Reports Data: $decoded");
        List<dynamic> newList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('content')) {
          newList = decoded['content'];
        } else if (decoded is List) {
          newList = decoded;
        }

        final currentList =
            isLoadMore ? (state.vehicleReports.value ?? []) : [];
        final updatedList = [...currentList, ...newList];

        state = state.copyWith(
          vehicleReports: AsyncValue.data(updatedList),
          vehicleReportsPage: currentPage,
          hasMoreVehicles: newList.length >= size,
          status: SecurityStatus.success,
        );
      } else {
        state = state.copyWith(
          status: SecurityStatus.failure,
          vehicleReports:
              isLoadMore
                  ? state.vehicleReports
                  : AsyncValue.error(
                    "Failed to fetch vehicle reports",
                    StackTrace.current,
                  ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SecurityStatus.failure,
        vehicleReports:
            isLoadMore
                ? state.vehicleReports
                : AsyncValue.error(e, StackTrace.current),
      );
    }
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
