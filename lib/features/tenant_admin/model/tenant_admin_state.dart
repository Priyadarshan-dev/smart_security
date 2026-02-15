import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TenantAdminStatus { initial, loading, success, failure }

class TenantAdminState {
  final TenantAdminStatus status;
  final AsyncValue<List<dynamic>> pendingApprovals;
  final AsyncValue<List<dynamic>> todayVisitors;
  final AsyncValue<List<dynamic>> allVisitors;
  final AsyncValue<List<dynamic>> vehicles;
  final bool isOperationLoading;

  TenantAdminState({
    this.status = TenantAdminStatus.initial,
    required this.pendingApprovals,
    required this.todayVisitors,
    required this.allVisitors,
    required this.vehicles,
    this.isOperationLoading = false,
  });

  TenantAdminState copyWith({
    TenantAdminStatus? status,
    AsyncValue<List<dynamic>>? pendingApprovals,
    AsyncValue<List<dynamic>>? todayVisitors,
    AsyncValue<List<dynamic>>? allVisitors,
    AsyncValue<List<dynamic>>? vehicles,
    bool? isOperationLoading,
  }) {
    return TenantAdminState(
      status: status ?? this.status,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      todayVisitors: todayVisitors ?? this.todayVisitors,
      allVisitors: allVisitors ?? this.allVisitors,
      vehicles: vehicles ?? this.vehicles,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
    );
  }

  factory TenantAdminState.initial() => TenantAdminState(
    status: TenantAdminStatus.initial,
    pendingApprovals: const AsyncValue.loading(),
    todayVisitors: const AsyncValue.loading(),
    allVisitors: const AsyncValue.loading(),
    vehicles: const AsyncValue.loading(),
  );

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'pendingApprovals': pendingApprovals.value ?? [],
      'todayVisitors': todayVisitors.value ?? [],
      'allVisitors': allVisitors.value ?? [],
      'vehicles': vehicles.value ?? [],
      'isOperationLoading': isOperationLoading,
    };
  }

  factory TenantAdminState.fromJson(Map<String, dynamic> json) {
    return TenantAdminState(
      status: TenantAdminStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TenantAdminStatus.initial,
      ),
      pendingApprovals: AsyncValue.data(json['pendingApprovals'] ?? []),
      todayVisitors: AsyncValue.data(json['todayVisitors'] ?? []),
      allVisitors: AsyncValue.data(json['allVisitors'] ?? []),
      vehicles: AsyncValue.data(json['vehicles'] ?? []),
      isOperationLoading: json['isOperationLoading'] ?? false,
    );
  }
}
