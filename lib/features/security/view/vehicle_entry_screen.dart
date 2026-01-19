import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controller/security_controller.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../../core/widgets/app_error_widget.dart';
import 'package:intl/intl.dart';

class VehicleEntryScreen extends ConsumerStatefulWidget {
  const VehicleEntryScreen({super.key});

  @override
  ConsumerState<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends ConsumerState<VehicleEntryScreen> {
  final _checkInSearchController = TextEditingController();
  final _checkOutSearchController = TextEditingController();
  String _checkInSearchQuery = "";
  String _checkOutSearchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(securityProvider.notifier).fetchVehicles();
      ref.read(securityProvider.notifier).fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);

    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text("Vehicle Management"),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showAddVehicleDialog(context),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      "ADD VEHICLE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: "Check-in"),
                  Tab(text: "Check-out"),
                  Tab(text: "History"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildCheckInTab(state),
                _buildCheckOutTab(state),
                _buildHistoryTab(state),
              ],
            ),
          ),
          if (state.isOperationLoading)
            Positioned.fill(
              child: Material(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: AppLoadingWidget()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckInTab(SecurityState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _checkInSearchController,
            decoration: InputDecoration(
              hintText: "Search vehicles...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_checkInSearchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _checkInSearchController.clear();
                          _checkInSearchQuery = "";
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final result = await _scanQR(
                        validator: (v) => v['status'] != 'CHECKED_IN',
                        invalidMessage: "Vehicle is already Checked In",
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _checkInSearchController.text = result;
                          _checkInSearchQuery = result;
                        });
                        SnackbarUtils.showSuccess(context, "Vehicle Found");
                      }
                    },
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (v) => setState(() => _checkInSearchQuery = v),
          ),
        ),
        Expanded(
          child: state.vehicles.when(
            data: (list) {
              final filtered =
                  list.where((v) => v['status'] != 'CHECKED_IN').where((v) {
                    final num =
                        (v['vehicleNumber'] ?? "").toString().toLowerCase();
                    return num.contains(_checkInSearchQuery.toLowerCase());
                  }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text("No vehicles found"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final vehicle = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getVehicleIcon(vehicle['vehicleType']),
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        vehicle['vehicleNumber'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Driver: ${vehicle['driverName']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap:
                                () => _showEditVehicleDialog(context, vehicle),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showDeleteDialog(context, vehicle),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: const Size(60, 32),
                            ),
                            onPressed: () async {
                              final company =
                                  vehicle['company'] ?? vehicle['companyName'];
                              if (company != null &&
                                  company.toString().isNotEmpty) {
                                // Automate check-in if company is already present
                                final success = await ref
                                    .read(securityProvider.notifier)
                                    .vehicleCheckIn(vehicle['id']);
                                if (context.mounted) {
                                  if (success) {
                                    SnackbarUtils.showSuccess(
                                      context,
                                      "Checked In Successfully",
                                    );
                                    DefaultTabController.of(
                                      context,
                                    )?.animateTo(1);
                                  } else {
                                    SnackbarUtils.showError(
                                      context,
                                      "Check-in Failed",
                                    );
                                  }
                                }
                              } else {
                                _showCheckInForm(context, vehicle);
                              }
                            },
                            child: const Text(
                              "IN",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoadingWidget(),
            error:
                (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry:
                      () => ref.read(securityProvider.notifier).fetchVehicles(),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckOutTab(SecurityState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _checkOutSearchController,
            decoration: InputDecoration(
              hintText: "Search checked-in vehicles...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_checkOutSearchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _checkOutSearchController.clear();
                          _checkOutSearchQuery = "";
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final result = await _scanQR(
                        validator: (v) => v['status'] == 'CHECKED_IN',
                        invalidMessage: "Vehicle is NOT Checked In",
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _checkOutSearchController.text = result;
                          _checkOutSearchQuery = result;
                        });
                        SnackbarUtils.showSuccess(context, "Vehicle Found");
                      }
                    },
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (v) => setState(() => _checkOutSearchQuery = v),
          ),
        ),
        Expanded(
          child: state.vehicles.when(
            data: (list) {
              final checkedIn =
                  list.where((v) => v['status'] == 'CHECKED_IN').where((v) {
                    final num =
                        (v['vehicleNumber'] ?? "").toString().toLowerCase();
                    return num.contains(_checkOutSearchQuery.toLowerCase());
                  }).toList();

              if (checkedIn.isEmpty) {
                return const Center(child: Text("No matching vehicles inside"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: checkedIn.length,
                itemBuilder: (context, index) {
                  final vehicle = checkedIn[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getVehicleIcon(vehicle['vehicleType']),
                        color: Colors.orange,
                      ),
                      title: Text(
                        vehicle['vehicleNumber'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Driver: ${vehicle['driverName']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap:
                                () => _showEditVehicleDialog(context, vehicle),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showDeleteDialog(context, vehicle),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: const Size(60, 32),
                            ),
                            onPressed: () async {
                              final success = await ref
                                  .read(securityProvider.notifier)
                                  .vehicleExit(vehicle['id']);
                              if (context.mounted) {
                                if (success) {
                                  SnackbarUtils.showSuccess(
                                    context,
                                    "Checked Out Successfully",
                                  );
                                } else {
                                  SnackbarUtils.showError(
                                    context,
                                    "Check-out Failed",
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "OUT",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoadingWidget(),
            error:
                (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry:
                      () => ref.read(securityProvider.notifier).fetchVehicles(),
                ),
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String? type) {
    switch (type) {
      case 'CAR':
        return Icons.directions_car;
      case 'BIKE':
        return Icons.motorcycle;
      case 'TRUCK':
        return Icons.local_shipping;
      default:
        return Icons.minor_crash;
    }
  }

  void _showAddVehicleDialog(BuildContext context) {
    final state = ref.read(securityProvider);
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final driverController = TextEditingController();
    String? selectedType = "CAR";
    String? selectedPurpose = "Employee";
    int? selectedTenantId;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text(
                    "New Vehicle Entry",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: numberController,
                            decoration: const InputDecoration(
                              labelText: "Vehicle Number",
                              hintText: "e.g. TN01AB1234",
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: driverController,
                            decoration: const InputDecoration(
                              labelText: "Driver Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            items:
                                ["CAR", "BIKE", "TRUCK", "OTHER"]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setDialogState(() => selectedType = v),
                            decoration: const InputDecoration(
                              labelText: "Type",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedPurpose,
                            items:
                                [
                                      "Employee",
                                      "Visitor",
                                      "Delivery",
                                      "Vendor",
                                      "Guest",
                                    ]
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) =>
                                    setDialogState(() => selectedPurpose = v),
                            decoration: const InputDecoration(
                              labelText: "Purpose",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: selectedTenantId,
                            items:
                                state.tenants
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t['id'] as int,
                                        child: Text(
                                          (t['company'] ??
                                                  t['companyName'] ??
                                                  'No Name')
                                              .toString(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) =>
                                    setDialogState(() => selectedTenantId = v),
                            decoration: const InputDecoration(
                              labelText: "Select Company",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null ? "Required" : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final selectedTenant = state.tenants.firstWhere(
                            (t) => t['id'] == selectedTenantId,
                          );
                          print(selectedTenant['companyName']);
                          print(selectedTenant['company']);
                          final success = await ref
                              .read(securityProvider.notifier)
                              .vehicleEntry({
                                "vehicleNumber": numberController.text,
                                "driverName": driverController.text,
                                "vehicleType": selectedType,
                                "purpose": selectedPurpose,
                                "company": selectedTenant['companyName'],
                              });
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              SnackbarUtils.showSuccess(
                                context,
                                "Vehicle Registered & Checked In",
                              );
                            } else {
                              SnackbarUtils.showError(
                                context,
                                "Registration Failed",
                              );
                            }
                          }
                        }
                      },
                      child: const Text(
                        "REGISTER",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, dynamic vehicle) {
    final state = ref.read(securityProvider);
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController(
      text: vehicle['vehicleNumber'],
    );
    final driverController = TextEditingController(
      text: vehicle['driverName'] ?? '',
    );
    String? selectedType = vehicle['vehicleType'] ?? "CAR";

    // Attempt to find tenant ID from vehicle's company name if tenantId is missing
    int? selectedTenantId = vehicle['tenantId'];
    final vehicleCompany = vehicle['company'] ?? vehicle['companyName'];
    if (selectedTenantId == null && vehicleCompany != null) {
      try {
        final tenant = state.tenants.firstWhere(
          (t) =>
              t['company']?.toString() == vehicleCompany.toString() ||
              t['companyName']?.toString() == vehicleCompany.toString(),
        );
        selectedTenantId = tenant['id'];
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text(
                    "Edit Vehicle",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: numberController,
                            decoration: const InputDecoration(
                              labelText: "Vehicle Number",
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: driverController,
                            decoration: const InputDecoration(
                              labelText: "Driver Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            items:
                                ["CAR", "BIKE", "TRUCK", "OTHER"]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setDialogState(() => selectedType = v),
                            decoration: const InputDecoration(
                              labelText: "Type",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: selectedTenantId,
                            items:
                                state.tenants
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t['id'] as int,
                                        child: Text(
                                          (t['company'] ??
                                                  t['companyName'] ??
                                                  'No Name')
                                              .toString(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) =>
                                    setDialogState(() => selectedTenantId = v),
                            decoration: const InputDecoration(
                              labelText: "Select Company",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null ? "Required" : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final selectedTenant = state.tenants.firstWhere(
                            (t) => t['id'] == selectedTenantId,
                          );
                          print(selectedTenant['companyName']);
                          print(selectedTenant['company']);
                          final success = await ref
                              .read(securityProvider.notifier)
                              .updateVehicle(vehicle['id'], {
                                "vehicleNumber": numberController.text,
                                "driverName": driverController.text,
                                "vehicleType": selectedType,
                                "company": selectedTenant['companyName'],
                              });
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              SnackbarUtils.showSuccess(
                                context,
                                "Vehicle Updated Successfully",
                              );
                            } else {
                              SnackbarUtils.showError(context, "Update Failed");
                            }
                          }
                        }
                      },
                      child: const Text(
                        "UPDATE",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic vehicle) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Vehicle"),
            content: Text(
              "Are you sure you want to delete ${vehicle['vehicleNumber']}?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final success = await ref
                      .read(securityProvider.notifier)
                      .deleteVehicle(vehicle['id']);
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      SnackbarUtils.showSuccess(context, "Vehicle Deleted");
                    } else {
                      SnackbarUtils.showError(context, "Delete Failed");
                    }
                  }
                },
                child: const Text("DELETE"),
              ),
            ],
          ),
    );
  }

  void _showCheckInForm(BuildContext context, dynamic vehicle) {
    final state = ref.read(securityProvider);
    final formKey = GlobalKey<FormState>();
    String? selectedPurpose = "Employee";
    int? selectedTenantId = vehicle['tenantId'];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    "Check-in: ${vehicle['vehicleNumber']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedPurpose,
                          items:
                              [
                                    "Employee",
                                    "Visitor",
                                    "Delivery",
                                    "Vendor",
                                    "Guest",
                                  ]
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setDialogState(() => selectedPurpose = v),
                          decoration: const InputDecoration(
                            labelText: "Purpose",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedTenantId,
                          items:
                              state.tenants
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t['id'] as int,
                                      child: Text(
                                        (t['company'] ??
                                                t['companyName'] ??
                                                'No Name')
                                            .toString(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setDialogState(() => selectedTenantId = v),
                          decoration: const InputDecoration(
                            labelText: "Select Company",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final selectedTenant = state.tenants.firstWhere(
                            (t) => t['id'] == selectedTenantId,
                          );
                          final success = await ref
                              .read(securityProvider.notifier)
                              .vehicleEntry({
                                "vehicleNumber": vehicle['vehicleNumber'],
                                "driverName": vehicle['driverName'],
                                "vehicleType": vehicle['vehicleType'],
                                "purpose": selectedPurpose,
                                "company": selectedTenant['company'],
                              });
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              SnackbarUtils.showSuccess(
                                context,
                                "Checked In Successfully",
                              );
                            } else {
                              SnackbarUtils.showError(
                                context,
                                "Check-in Failed",
                              );
                            }
                          }
                        }
                      },
                      child: const Text(
                        "CHECK-IN",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildHistoryTab(SecurityState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search history...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged:
                (v) => setState(
                  () => _checkInSearchQuery = v,
                ), // Reusing check-in query for simplicity or add history one
          ),
        ),
        Expanded(
          child: state.vehicles.when(
            data: (list) {
              final history =
                  list.where((v) {
                    final num =
                        (v['vehicleNumber'] ?? "").toString().toLowerCase();
                    return num.contains(_checkInSearchQuery.toLowerCase());
                  }).toList();

              if (history.isEmpty) {
                return const Center(child: Text("No history found"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final vehicle = history[index];
                  final entryTime =
                      vehicle['entryTime'] != null
                          ? DateFormat(
                            'dd/MM HH:mm',
                          ).format(DateTime.parse(vehicle['entryTime']))
                          : 'N/A';
                  final exitTime =
                      vehicle['exitTime'] != null
                          ? DateFormat(
                            'dd/MM HH:mm',
                          ).format(DateTime.parse(vehicle['exitTime']))
                          : 'N/A';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getVehicleIcon(vehicle['vehicleType']),
                        color: Colors.blueGrey,
                      ),
                      title: Text(
                        vehicle['vehicleNumber'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${vehicle['driverName']} / ${vehicle['company'] ?? vehicle['companyName'] ?? 'N/A'}",
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "IN: $entryTime",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "OUT: $exitTime",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoadingWidget(),
            error:
                (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry:
                      () => ref.read(securityProvider.notifier).fetchVehicles(),
                ),
          ),
        ),
      ],
    );
  }

  Future<String?> _scanQR({
    bool Function(Map<String, dynamic>)? validator,
    String? invalidMessage,
  }) async {
    final state = ref.read(securityProvider);

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
            height: 500,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Scan Vehicle QR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            final code = barcode.rawValue!;

                            Map<String, dynamic>? vehicle;
                            try {
                              vehicle = state.vehicles.value?.firstWhere(
                                (v) =>
                                    (v['vehicleNumber'] ?? "")
                                        .toString()
                                        .toLowerCase() ==
                                    code.toLowerCase(),
                              );
                            } catch (_) {}

                            if (vehicle != null) {
                              if (validator != null && !validator(vehicle)) {
                                Navigator.pop(sheetContext);
                                SnackbarUtils.showError(
                                  context,
                                  invalidMessage ?? "Invalid vehicle status",
                                );
                              } else {
                                Navigator.pop(sheetContext, code);
                              }
                            } else {
                              Navigator.pop(sheetContext);
                              SnackbarUtils.showError(
                                context,
                                "Please scan a valid Vehicle QR",
                              );
                            }
                            return;
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Align QR code within the frame",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}
