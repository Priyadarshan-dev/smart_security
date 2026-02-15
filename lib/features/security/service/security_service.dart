import 'package:ceedeeyes/core/api/api_client.dart';
import 'package:http/http.dart' as http;

class SecurityService {
  final ApiClient _api;

  SecurityService(this._api);

  Future<http.Response> getTodayVisitors() async {
    return await _api.get("/security/visitors/today");
  }

  Future<http.Response> checkInVisitor(int visitorId) async {
    return await _api.post("/security/visitors/$visitorId/check-in", {});
  }

  Future<http.Response> checkOutVisitor(int visitorId) async {
    return await _api.post("/security/visitors/$visitorId/check-out", {});
  }

  Future<http.Response> addWalkIn(Map<String, dynamic> data) async {
    return await _api.post("/security/visitors/walk-in", data);
  }

  Future<http.Response> vehicleEntry(Map<String, dynamic> data) async {
    return await _api.post("/security/vehicles/entry", data);
  }

  Future<http.Response> vehicleExit(int id) async {
    return await _api.post("/security/vehicles/$id/exit", {});
  }

  Future<http.Response> vehicleCheckIn(int id) async {
    return await _api.post("/security/vehicles/$id/check-in", {});
  }

  Future<http.Response> getTenants() async {
    return await _api.get("/security/tenants/all");
  }

  Future<http.Response> getVehicles() async {
    return await _api.get("/security/vehicles/all");
  }

  // ---------------------------------Staff Section---------------------------------
  Future<http.Response> getStaffs() async {
    return await _api.get("/security/getAllStaff");
  }

  Future<http.Response> staffCheckIn(int id) async {
    return await _api.post("/security/staff/$id/check-in", {});
  }

  Future<http.Response> staffCheckOut(int id) async {
    return await _api.post("/security/staff/$id/check-out", {});
  }

  Future<http.Response> getStaffHistory(
    String startDate,
    String endDate,
    int page,
    int size,
  ) async {
    return await _api.get(
      "/security/staff/history?startDate=$startDate&endDate=$endDate&page=$page&size=$size",
    );
  }
  //--------------------------------End---------------------------------------------

  Future<http.Response> updateVehicle(int id, Map<String, dynamic> data) async {
    return await _api.put("/security/vehicles/$id", data);
  }

  Future<http.Response> deleteVehicle(int id) async {
    return await _api.delete("/security/vehicles/$id");
  }

  Future<http.Response> getVisitorHistory(
    String startDate,
    String endDate,
    int page,
    int size,
  ) async {
    return await _api.get(
      "/security/visitors/history?startDate=$startDate&endDate=$endDate&page=$page&size=$size",
    );
  }

  Future<http.Response> getVehicleHistory(
    String startDate,
    String endDate,
    int page,
    int size,
  ) async {
    return await _api.get(
      "/security/vehicles/history?startDate=$startDate&endDate=$endDate&page=$page&size=$size",
    );
  }
}
