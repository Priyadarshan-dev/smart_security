import 'package:ceedeeyes/core/api/api_client.dart';
import 'package:http/http.dart' as http;

class TenantAdminService {
  final ApiClient _api;

  TenantAdminService(this._api);

  Future<http.Response> getPendingApprovals() async {
    return await _api.get("/tenant-admin/approvals/pending");
  }

  Future<http.Response> getTodayVisitors() async {
    return await _api.get("/tenant-admin/visitors/today");
  }

  Future<http.Response> getAllVisitors() async {
    return await _api.get("/tenant-admin/visitors");
  }

  Future<http.Response> approveOrReject(
    int visitorId,
    Map<String, dynamic> data,
  ) async {
    return await _api.patch("/tenant-admin/approvals/$visitorId", data);
  }

  Future<http.Response> scheduleVisitor(Map<String, dynamic> data) async {
    return await _api.post("/tenant-admin/visitors/schedule", data);
  }

  Future<http.Response> updateVisitor(
    int visitorId,
    Map<String, dynamic> data,
  ) async {
    return await _api.put("/tenant-admin/visitors/$visitorId", data);
  }

  Future<http.Response> deleteVisitor(int visitorId) async {
    return await _api.delete("/tenant-admin/visitors/$visitorId");
  }

  Future<http.Response> getTenantVehicles() async {
    return await _api.get("/security/vehicles/tenant");
  }

  Future<http.Response> addVehicle(Map<String, dynamic> data) async {
    return await _api.post("/tenant-admin/tenantsVehicles/entry", data);
  }

  Future<http.Response> updateVehicle(int id, Map<String, dynamic> data) async {
    return await _api.put("/tenant-admin/tenantsVehicles/$id", data);
  }

  Future<http.Response> deleteVehicle(int id) async {
    return await _api.delete("/tenant-admin/tenantsVehicles/$id");
  }
}
