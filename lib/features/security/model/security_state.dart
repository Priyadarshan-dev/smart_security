import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ceedeeyes/features/security/model/staff_model.dart';

enum SecurityStatus { initial, loading, success, failure }

class SecurityState {
  final SecurityStatus status;
  final AsyncValue<List<dynamic>> todayVisitors;
  final List<dynamic> tenants;
  final List<dynamic> tenantAdmins;
  final AsyncValue<List<dynamic>> vehicles;
  final AsyncValue<List<dynamic>> visitorReports;
  final AsyncValue<List<dynamic>> vehicleReports;
  final AsyncValue<List<dynamic>> staffReports;

  // ✅ Simple Staff Fields
  final List<StaffModel> staffs;
  final bool isStaffLoading;
  final String? staffError;

  final bool isOperationLoading;
  final int visitorReportsPage;
  final bool hasMoreVisitors;
  final int vehicleReportsPage;
  final bool hasMoreVehicles;
  final int staffReportsPage;
  final bool hasMoreStaffs;

  SecurityState({
    required this.status,
    required this.todayVisitors,
    required this.tenants,
    required this.tenantAdmins,
    required this.vehicles,
    required this.visitorReports,
    required this.vehicleReports,
    required this.staffReports,

    // ✅ Staff Constructor
    required this.staffs,
    required this.isStaffLoading,
    this.staffError,

    required this.isOperationLoading,
    this.visitorReportsPage = 0,
    this.hasMoreVisitors = true,
    this.vehicleReportsPage = 0,
    this.hasMoreVehicles = true,
    this.staffReportsPage = 0,
    this.hasMoreStaffs = true,
  });

  factory SecurityState.initial() {
    return SecurityState(
      status: SecurityStatus.initial,
      todayVisitors: const AsyncValue.data([]),
      tenants: [],
      tenantAdmins: [],
      vehicles: const AsyncValue.data([]),
      visitorReports: const AsyncValue.data([]),
      vehicleReports: const AsyncValue.data([]),
      staffReports: const AsyncValue.data([]),

      // ✅ Staff Initial
      staffs: [],
      isStaffLoading: false,
      staffError: null,

      isOperationLoading: false,
      visitorReportsPage: 0,
      hasMoreVisitors: true,
      vehicleReportsPage: 0,
      hasMoreVehicles: true,
      staffReportsPage: 0,
      hasMoreStaffs: true,
    );
  }

  SecurityState copyWith({
    SecurityStatus? status,
    AsyncValue<List<dynamic>>? todayVisitors,
    List<dynamic>? tenants,
    List<dynamic>? tenantAdmins,
    AsyncValue<List<dynamic>>? vehicles,
    AsyncValue<List<dynamic>>? visitorReports,
    AsyncValue<List<dynamic>>? vehicleReports,
    AsyncValue<List<dynamic>>? staffReports,

    // ✅ Staff copyWith
    List<StaffModel>? staffs,
    bool? isStaffLoading,
    String? staffError,

    bool? isOperationLoading,
    int? visitorReportsPage,
    bool? hasMoreVisitors,
    int? vehicleReportsPage,
    bool? hasMoreVehicles,
    int? staffReportsPage,
    bool? hasMoreStaffs,
  }) {
    return SecurityState(
      status: status ?? this.status,
      todayVisitors: todayVisitors ?? this.todayVisitors,
      tenants: tenants ?? this.tenants,
      tenantAdmins: tenantAdmins ?? this.tenantAdmins,
      vehicles: vehicles ?? this.vehicles,
      visitorReports: visitorReports ?? this.visitorReports,
      vehicleReports: vehicleReports ?? this.vehicleReports,
      staffReports: staffReports ?? this.staffReports,

      // ✅ Staff copyWith
      staffs: staffs ?? this.staffs,
      isStaffLoading: isStaffLoading ?? this.isStaffLoading,
      staffError: staffError ?? this.staffError,

      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      visitorReportsPage: visitorReportsPage ?? this.visitorReportsPage,
      hasMoreVisitors: hasMoreVisitors ?? this.hasMoreVisitors,
      vehicleReportsPage: vehicleReportsPage ?? this.vehicleReportsPage,
      hasMoreVehicles: hasMoreVehicles ?? this.hasMoreVehicles,
      staffReportsPage: staffReportsPage ?? this.staffReportsPage,
      hasMoreStaffs: hasMoreStaffs ?? this.hasMoreStaffs,
    );
  }
}
