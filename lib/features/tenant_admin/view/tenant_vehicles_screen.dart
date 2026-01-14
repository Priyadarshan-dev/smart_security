import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Vehicle", style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await ref.read(tenantAdminProvider.notifier).addVehicle({
                  "vehicleNumber": numberController.text,
                  "driverName": driverController.text,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    SnackbarUtils.showSuccess(context, "Vehicle added successfully");
                  } else {
                    SnackbarUtils.showError(context, "Failed to add vehicle");
                  }
                }
              }
            },
            child: const Text("ADD VEHICLE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<TenantVehiclesScreen> createState() => _TenantVehiclesScreenState();
}

class _TenantVehiclesScreenState extends ConsumerState<TenantVehiclesScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tenantAdminProvider.notifier).fetchTenantVehicles());
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: state.vehicles.when(
            data: (vehicles) {
              final filtered = vehicles.where((v) {
                final num = (v['vehicleNumber'] ?? "").toString().toLowerCase();
                final driver = (v['driverName'] ?? "").toString().toLowerCase();
                return num.contains(_searchQuery.toLowerCase()) || 
                       driver.contains(_searchQuery.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text("No vehicles match your search"));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final vehicle = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(Icons.directions_car, color: Theme.of(context).primaryColor),
                      ),
                      title: Text(
                        vehicle['vehicleNumber'] ?? "N/A",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(vehicle['driverName'] ?? "No driver assigned"),
                      trailing: IconButton(
                        icon: const Icon(Icons.qr_code),
                        onPressed: () => _showQRDialog(context, vehicle['vehicleNumber']),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoadingWidget(),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.read(tenantAdminProvider.notifier).fetchTenantVehicles(),
            ),
          ),
        ),
      ],
    );
  }

  void _showQRDialog(BuildContext context, String vehicleNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("QR Code: $vehicleNumber"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: vehicleNumber,
                  version: QrVersions.auto,
                  size: 200.0,
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share, size: 18),
            label: const Text("SHARE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _shareQR(vehicleNumber),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 18),
            label: const Text("SAVE"),
            onPressed: () => _saveQR(vehicleNumber),
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
        final imagePath = await File('${directory.path}/qr_$vehicleNumber.png').create();
        await imagePath.writeAsBytes(image);
        
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Security QR for vehicle $vehicleNumber',
        );
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Share failed: $e");
    }
  }

  Future<void> _saveQR(String vehicleNumber) async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        // Simple download mock for now or save to gallery if needed
        // For mobile, we usually save to internal storage or gallery
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/qr_$vehicleNumber.png';
        final file = File(path);
        await file.writeAsBytes(image);
        
        if (mounted) SnackbarUtils.showSuccess(context, "Saved to: $path");
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Save failed: $e");
    }
  }
}
