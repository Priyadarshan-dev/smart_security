import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../controller/tenant_admin_controller.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/utils/snackbar_utils.dart';

class TenantVehiclesScreen extends ConsumerStatefulWidget {
  const TenantVehiclesScreen({super.key});

  static void showAddVehicleDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final driverController = TextEditingController();

    String selectedVehicleType = "CAR";
    final List<String> vehicleTypes = ["CAR", "BIKE", "TRUCK", "OTHER"];

    String selectedPurpose = "Employee";
    final List<String> purposes = [
      "Employee",
      "Visitor",
      "Delivery",
      "Vendor",
      "Other",
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text(
                    "Add New Vehicle",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Form(
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
                          value: selectedVehicleType,
                          items:
                              vehicleTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => selectedVehicleType = v!),
                          decoration: const InputDecoration(
                            labelText: "Vehicle Type",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedPurpose,
                          items:
                              purposes
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => selectedPurpose = v!),
                          decoration: const InputDecoration(
                            labelText: "Purpose",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionsPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final success = await ref
                                    .read(tenantAdminProvider.notifier)
                                    .addVehicle({
                                      "vehicleNumber": numberController.text,
                                      "driverName": driverController.text,
                                      "vehicleType": selectedVehicleType,
                                      "purpose": selectedPurpose,
                                    });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  if (success) {
                                    SnackbarUtils.showSuccess(
                                      context,
                                      "Vehicle added successfully",
                                    );
                                  } else {
                                    SnackbarUtils.showError(
                                      context,
                                      "Failed to add vehicle",
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text(
                              "ADD VEHICLE",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
    );
  }

  static void showEditVehicleDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> vehicle,
  ) {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController(
      text: vehicle['vehicleNumber'],
    );
    final driverController = TextEditingController(text: vehicle['driverName']);

    String selectedVehicleType = vehicle['vehicleType'] ?? "CAR";
    final List<String> vehicleTypes = ["CAR", "BIKE", "TRUCK", "OTHER"];
    if (!vehicleTypes.contains(selectedVehicleType))
      selectedVehicleType = "OTHER";

    String selectedPurpose = vehicle['purpose'] ?? "Employee";
    final List<String> purposes = [
      "Employee",
      "Visitor",
      "Delivery",
      "Vendor",
      "Other",
    ];
    if (!purposes.contains(selectedPurpose)) selectedPurpose = "Other";

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text(
                    "Edit Vehicle",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Form(
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
                          value: selectedVehicleType,
                          items:
                              vehicleTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => selectedVehicleType = v!),
                          decoration: const InputDecoration(
                            labelText: "Vehicle Type",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedPurpose,
                          items:
                              purposes
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => selectedPurpose = v!),
                          decoration: const InputDecoration(
                            labelText: "Purpose",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionsPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final success = await ref
                                    .read(tenantAdminProvider.notifier)
                                    .updateVehicle(vehicle['id'], {
                                      "vehicleNumber": numberController.text,
                                      "driverName": driverController.text,
                                      "vehicleType": selectedVehicleType,
                                      "purpose": selectedPurpose,
                                    });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  if (success) {
                                    SnackbarUtils.showSuccess(
                                      context,
                                      "Vehicle updated successfully",
                                    );
                                  } else {
                                    SnackbarUtils.showError(
                                      context,
                                      "Failed to update vehicle",
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text(
                              "UPDATE",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
    );
  }

  static void showDeleteVehicleDialog(
    BuildContext context,
    WidgetRef ref,
    int vehicleId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Vehicle"),
            content: const Text(
              "Are you sure you want to delete this vehicle?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(tenantAdminProvider.notifier)
                      .deleteVehicle(vehicleId);
                  if (context.mounted) {
                    if (success) {
                      SnackbarUtils.showSuccess(
                        context,
                        "Vehicle deleted successfully",
                      );
                    } else {
                      SnackbarUtils.showError(
                        context,
                        "Failed to delete vehicle",
                      );
                    }
                  }
                },
                child: const Text(
                  "DELETE",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  ConsumerState<TenantVehiclesScreen> createState() =>
      _TenantVehiclesScreenState();
}

class _TenantVehiclesScreenState extends ConsumerState<TenantVehiclesScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tenantAdminProvider.notifier).fetchTenantVehicles(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantAdminProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search vehicles...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: state.vehicles.when(
            data: (vehicles) {
              final filtered =
                  vehicles.where((v) {
                    final num =
                        (v['vehicleNumber'] ?? "").toString().toLowerCase();
                    final driver =
                        (v['driverName'] ?? "").toString().toLowerCase();
                    return num.contains(_searchQuery.toLowerCase()) ||
                        driver.contains(_searchQuery.toLowerCase());
                  }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text("No vehicles match your search"),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final vehicle = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.directions_car,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(
                        vehicle['vehicleNumber'] ?? "N/A",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        vehicle['driverName'] ?? "No driver assigned",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () =>
                                    TenantVehiclesScreen.showEditVehicleDialog(
                                      context,
                                      ref,
                                      vehicle,
                                    ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed:
                                () =>
                                    TenantVehiclesScreen.showDeleteVehicleDialog(
                                      context,
                                      ref,
                                      vehicle['id'],
                                    ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code),
                            onPressed:
                                () => _showQRDialog(
                                  context,
                                  vehicle['vehicleNumber'],
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
                      () =>
                          ref
                              .read(tenantAdminProvider.notifier)
                              .fetchTenantVehicles(),
                ),
          ),
        ),
      ],
    );
  }

  void _showQRDialog(BuildContext context, String vehicleNumber) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("QR Code: $vehicleNumber"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: QrImageView(
                            data: vehicleNumber,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Present this QR for faster entry/exit",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text("SHARE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _shareQR(vehicleNumber),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text("SAVE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _saveQR(vehicleNumber),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Future<void> _shareQR(String vehicleNumber) async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            await File('${directory.path}/qr_$vehicleNumber.png').create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles([
          XFile(imagePath.path),
        ], text: 'Security QR for vehicle $vehicleNumber');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Share failed: $e");
    }
  }

  Future<void> _saveQR(String vehicleNumber) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        await Gal.putImageBytes(image, name: "QR_$vehicleNumber");
        if (mounted)
          SnackbarUtils.showSuccess(context, "QR saved successfully");
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Save failed: $e");
    }
  }
}
