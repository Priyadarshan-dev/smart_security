import 'dart:io';
import 'dart:typed_data';
import 'package:ceedeeyes/core/storage/storage_service.dart';
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

    // const primaryColor = Color(0xFF1E3A8A);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  title: const Text(
                    "Add New Vehicle",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: numberController,
                            decoration: InputDecoration(
                              labelText: "Vehicle Number",
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: "e.g. TN01AB1234",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: driverController,
                            decoration: InputDecoration(
                              labelText: "Driver Name",
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: "Enter Driver Name",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),
                          FormField<String>(
                            initialValue: selectedVehicleType,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<String>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedVehicleType,
                                    label: const Text(
                                      "Vehicle Type",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        selectedVehicleType == "CAR"
                                            ? 'assets/icons/car_icon.png'
                                            : 'assets/icons/other_icon.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                    ),
                                    dropdownMenuEntries:
                                        vehicleTypes.map((t) {
                                          return DropdownMenuEntry<String>(
                                            value: t,
                                            label: t,
                                            leadingIcon: Image.asset(
                                              t == "CAR"
                                                  ? 'assets/icons/car_icon.png'
                                                  : 'assets/icons/other_icon.png',
                                              width: 24,
                                              height: 24,
                                            ),
                                          );
                                        }).toList(),
                                    onSelected: (v) {
                                      setState(() => selectedVehicleType = v!);
                                      fieldState.didChange(v);
                                    },
                                  ),
                                  if (fieldState.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        top: 6,
                                      ),
                                      child: Text(
                                        fieldState.errorText!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          FormField<String>(
                            initialValue: selectedPurpose,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<String>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedPurpose,
                                    label: const Text(
                                      "Purpose",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        (() {
                                          switch (selectedPurpose) {
                                            case "Employee":
                                              return 'assets/icons/interview_icon.png';
                                            case "Visitor":
                                              return 'assets/icons/visitor_icon.png';
                                            case "Delivery":
                                              return 'assets/icons/delivery_icon.png';
                                            case "Vendor":
                                              return 'assets/icons/vendor_icon.png';
                                            default:
                                              return 'assets/icons/other_icon.png';
                                          }
                                        })(),
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                    ),
                                    dropdownMenuEntries:
                                        purposes.map((p) {
                                          String assetPath;
                                          switch (p) {
                                            case "Employee":
                                              assetPath =
                                                  'assets/icons/interview_icon.png';
                                              break;
                                            case "Visitor":
                                              assetPath =
                                                  'assets/icons/visitor_icon.png';
                                              break;
                                            case "Delivery":
                                              assetPath =
                                                  'assets/icons/delivery_icon.png';
                                              break;
                                            case "Vendor":
                                              assetPath =
                                                  'assets/icons/vendor_icon.png';
                                              break;
                                            default:
                                              assetPath =
                                                  'assets/icons/other_icon.png';
                                          }
                                          return DropdownMenuEntry<String>(
                                            value: p,
                                            label: p,
                                            leadingIcon: Image.asset(
                                              assetPath,
                                              width: 24,
                                              height: 24,
                                            ),
                                          );
                                        }).toList(),
                                    onSelected: (v) {
                                      setState(() => selectedPurpose = v!);
                                      fieldState.didChange(v);
                                    },
                                  ),
                                  if (fieldState.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        top: 6,
                                      ),
                                      child: Text(
                                        fieldState.errorText!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actionsPadding: const EdgeInsets.all(16),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                    print(
                                      "Vechile Added Successfully :$success",
                                    );
                                    SnackbarUtils.showSuccess(
                                      context,
                                      "Vehicle added successfully",
                                    );
                                    // print("Vehicle added successfully$");
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
    if (!vehicleTypes.contains(selectedVehicleType)) {
      selectedVehicleType = "OTHER";
    }

    String selectedPurpose = vehicle['purpose'] ?? "Employee";
    final List<String> purposes = [
      "Employee",
      "Visitor",
      "Delivery",
      "Vendor",
      "Other",
    ];
    if (!purposes.contains(selectedPurpose)) selectedPurpose = "Other";

    //  const primaryColor = Color(0xFF1E3A8A);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  title: const Text(
                    "Edit Vehicle",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: numberController,
                            decoration: InputDecoration(
                              labelText: "Vehicle Number",
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: "e.g. TN01AB1234",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: driverController,
                            decoration: InputDecoration(
                              labelText: "Driver Name",
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: "Enter Driver Name",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),
                          FormField<String>(
                            initialValue: selectedVehicleType,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<String>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedVehicleType,
                                    label: const Text(
                                      "Vehicle Type",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        selectedVehicleType == "CAR"
                                            ? 'assets/icons/car_icon.png'
                                            : 'assets/icons/other_icon.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                    ),
                                    dropdownMenuEntries:
                                        vehicleTypes.map((t) {
                                          return DropdownMenuEntry<String>(
                                            value: t,
                                            label: t,
                                            leadingIcon: Image.asset(
                                              t == "CAR"
                                                  ? 'assets/icons/car_icon.png'
                                                  : 'assets/icons/other_icon.png',
                                              width: 24,
                                              height: 24,
                                            ),
                                          );
                                        }).toList(),
                                    onSelected: (v) {
                                      setState(() => selectedVehicleType = v!);
                                      fieldState.didChange(v);
                                    },
                                  ),
                                  if (fieldState.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        top: 6,
                                      ),
                                      child: Text(
                                        fieldState.errorText!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          FormField<String>(
                            initialValue: selectedPurpose,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<String>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedPurpose,
                                    label: const Text(
                                      "Purpose",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        (() {
                                          switch (selectedPurpose) {
                                            case "Employee":
                                              return 'assets/icons/interview_icon.png';
                                            case "Visitor":
                                              return 'assets/icons/visitor_icon.png';
                                            case "Delivery":
                                              return 'assets/icons/delivery_icon.png';
                                            case "Vendor":
                                              return 'assets/icons/vendor_icon.png';
                                            default:
                                              return 'assets/icons/other_icon.png';
                                          }
                                        })(),
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 15,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                    ),
                                    dropdownMenuEntries:
                                        purposes.map((p) {
                                          String assetPath;
                                          switch (p) {
                                            case "Employee":
                                              assetPath =
                                                  'assets/icons/interview_icon.png';
                                              break;
                                            case "Visitor":
                                              assetPath =
                                                  'assets/icons/visitor_icon.png';
                                              break;
                                            case "Delivery":
                                              assetPath =
                                                  'assets/icons/delivery_icon.png';
                                              break;
                                            case "Vendor":
                                              assetPath =
                                                  'assets/icons/vendor_icon.png';
                                              break;
                                            default:
                                              assetPath =
                                                  'assets/icons/other_icon.png';
                                          }
                                          return DropdownMenuEntry<String>(
                                            value: p,
                                            label: p,
                                            leadingIcon: Image.asset(
                                              assetPath,
                                              width: 24,
                                              height: 24,
                                            ),
                                          );
                                        }).toList(),
                                    onSelected: (v) {
                                      setState(() => selectedPurpose = v!);
                                      fieldState.didChange(v);
                                    },
                                  ),
                                  if (fieldState.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        top: 6,
                                      ),
                                      child: Text(
                                        fieldState.errorText!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actionsPadding: const EdgeInsets.all(16),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text(
              "Delete Vehicle",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            content: const Text(
              "Are you sure you want to delete this vehicle?",
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
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
              labelText: "Search",
              labelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              floatingLabelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              hintText: "Search vehicles...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
              ),
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
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vehicle Icon
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey.shade100,
                                child: Image.asset(
                                  'assets/icons/car_icon.png',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Vehicle Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Vehicle: ${vehicle['vehicleNumber'] ?? 'N/A'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Driver Name
                                    Text(
                                      "Driver: ${vehicle['driverName'] ?? 'No driver assigned'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Purpose
                                    Text(
                                      "Purpose: ${vehicle['purpose'] ?? 'N/A'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Company Name
                                    Text(
                                      "Company: ${vehicle['company'] ?? 'N/A'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () =>
                                          TenantVehiclesScreen.showEditVehicleDialog(
                                            context,
                                            ref,
                                            vehicle,
                                          ),
                                  icon: Image.asset(
                                    'assets/icons/edit_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Edit",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () =>
                                          TenantVehiclesScreen.showDeleteVehicleDialog(
                                            context,
                                            ref,
                                            vehicle['id'],
                                          ),
                                  icon: Image.asset(
                                    'assets/icons/delete_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Delete",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF43F5E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _showQRDialog(
                                        context,
                                        vehicle['vehicleNumber'],
                                        vehicle['company'],
                                      ),
                                  icon: Image.asset(
                                    'assets/icons/qr_code_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "QR",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
        // Sticky Add Vehicle Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed:
                  () => TenantVehiclesScreen.showAddVehicleDialog(context, ref),
              icon: Image.asset(
                'assets/icons/car_icon.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              label: const Text(
                "Add Vehicle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showQRDialog(
    BuildContext context,
    String vehicleNumber,
    String? companyName,
  ) {
    final storageService = StorageService();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("QR Code: $vehicleNumber"),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: 250,
                    // Increased height to accommodate text
                    height: 280,
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (companyName != null && companyName.isNotEmpty)
                              Text(
                                "Company Name: $companyName",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              )
                            else
                              FutureBuilder<String?>(
                                future: storageService.getCompanyName(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text("Loading...");
                                  }
                                  return Text(
                                    "Company Name: ${snapshot.data ?? ""}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 10),
                            QrImageView(
                              data: vehicleNumber,
                              version: QrVersions.auto,
                              size: 180.0,
                              backgroundColor: Colors.white,
                            ),
                          ],
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
        if (mounted) {
          SnackbarUtils.showSuccess(context, "QR saved successfully");
        }
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Save failed: $e");
    }
  }
}
