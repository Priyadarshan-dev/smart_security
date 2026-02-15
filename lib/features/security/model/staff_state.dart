// import 'package:ceedeeyes/features/security/model/staff_model.dart';
//
// enum StaffStateStatus { initial, loading, success, failure }
//
// class StaffState {
//   final StaffStateStatus status;
//   final List<StaffModel> staffs;
//
//   StaffState({required this.status, required this.staffs});
//
//   factory StaffState.initial() {
//     return StaffState(status: StaffStateStatus.initial, staffs: []);
//   }
//
//   StaffState copyWith({StaffStateStatus? status, List<StaffModel>? staffs}) {
//     return StaffState(
//       status: status ?? this.status,
//       staffs: staffs ?? this.staffs,
//     );
//   }
//
//   factory StaffState.fromJson(Map<String, dynamic> json) {
//     return StaffState(
//       status: StaffStateStatus.values.firstWhere(
//         (e) => e.name == json['status'],
//         orElse: () => StaffStateStatus.initial,
//       ),
//       staffs: json['staffs'] ?? [],
//     );
//   }
// }
