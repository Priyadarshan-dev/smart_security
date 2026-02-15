class StaffModel {
  final int id;
  final String staffName;
  final String employeeId;
  final int phoneNumber;
  final String address;
  final int idProof;
  final String status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  StaffModel({
    required this.id,
    required this.staffName,
    required this.employeeId,
    required this.phoneNumber,
    required this.address,
    required this.idProof,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });
//{
//     "id": 2,
//     "employeeCode": "R001",
//     "address": "TBM",
//     "name": "Arun",
//     "mobileNumber": "9791277722",
//     "idProof": "GUAH",
//     "status": "PENDING",
//     "createdBy": 1,
//     "createdAt": "2026-02-12T09:42:42.318505",
//     "checkInTime": null,
//     "checkOutTime": null
//   }
  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? 0,
      staffName: (json['name'] ?? "").toString(),
      employeeId: (json['employeeCode']??'').toString(),
      phoneNumber: int.tryParse(json['mobileNumber']?.toString() ?? "0") ?? 0,
      address: (json['address'] ?? "").toString(),
      idProof: int.tryParse(json['idProof']?.toString() ?? "0") ?? 0,
      status: (json['status'] ?? "").toString(),
      checkInTime:
          json['checkInTime'] != null
              ? DateTime.tryParse(json['checkInTime'].toString())
              : null,
      checkOutTime:
          json['checkOutTime'] != null
              ? DateTime.tryParse(json['checkOutTime'].toString())
              : null,
    );
  }

  StaffModel copyWith({
  int? id,
  String? staffName,
  String? employeeId,
  int? phoneNumber,
  String? address,
  int? idProof,
  String? status,
  DateTime? checkInTime,
  DateTime? checkOutTime,
}) {
  return StaffModel(
    id: id ?? this.id,
    staffName: staffName ?? this.staffName,
    employeeId: employeeId ?? this.employeeId,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    address: address ?? this.address,
    idProof: idProof ?? this.idProof,
    status: status ?? this.status,
    checkInTime: checkInTime ?? this.checkInTime,
    checkOutTime: checkOutTime ?? this.checkOutTime,
  );
}

}
