import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ceedeeyes/core/theme/app_theme.dart';
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
  DateTime _historyStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _historyEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(securityProvider.notifier).fetchVehicles();
      ref.read(securityProvider.notifier).fetchTenants();
      ref
          .read(securityProvider.notifier)
          .fetchVehicleReports(_historyStartDate, _historyEndDate);
    });
  }

  Future<void> _selectHistoryDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _historyStartDate : _historyEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isStart && picked.isAfter(_historyEndDate)) {
        if (context.mounted) {
          SnackbarUtils.showError(context, "From date cannot be after To date");
        }
        return;
      }
      if (!isStart && picked.isBefore(_historyStartDate)) {
        if (context.mounted) {
          SnackbarUtils.showError(
            context,
            "To date cannot be before From date",
          );
        }
        return;
      }
      setState(() {
        if (isStart) {
          _historyStartDate = picked;
        } else {
          _historyEndDate = picked;
        }
      });
      ref
          .read(securityProvider.notifier)
          .fetchVehicleReports(_historyStartDate, _historyEndDate);
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(value.toString());
      return DateFormat('dd.MM.yy h.mm a').format(dateTime);
    } catch (e) {
      // Handle time-only format like 15:57:32.576
      try {
        if (value.toString().contains(':')) {
          final parts = value.toString().split(':');
          if (parts.length >= 2) {
            final now = DateTime.now();
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final secondPart = parts.length > 2 ? parts[2].split('.') : ['0'];
            final second = int.parse(secondPart[0]);

            final dateTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
              second,
            );
            return DateFormat('dd.MM.yy h.mm a').format(dateTime);
          }
        }
      } catch (_) {}
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);

    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppTheme.securityBackgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.securityAppBarColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              title: Text(
                "Vehicle Management",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Custom Pill TabBar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.securityTabBarColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 3.0,
                          color: Color(0xFF5D4037),
                        ),
                        insets: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      labelColor: const Color(0xFF5D4037),
                      unselectedLabelColor: Colors.grey.shade400,
                      overlayColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ),
                      tabs: const [
                        Tab(text: "Check-in"),
                        Tab(text: "Check-out"),
                        Tab(text: "History"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCheckInTab(state),
                        _buildCheckOutTab(state),
                        _buildHistoryTab(state),
                      ],
                    ),
                  ),
                ],
              ),
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
              labelText: "Search Vehicles",
              hintText: "Search Vehicles",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              labelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              floatingLabelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 20,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                    icon: Image.asset(
                      'assets/icons/qr_scan_icon.png',
                      width: 24,
                      height: 24,
                    ),
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
              ),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final vehicle = filtered[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/icons/car_icon.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Number: ${vehicle['vehicleNumber'] ?? ''}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      "Driver: ${vehicle['driverName'] ?? ''}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  foregroundColor: Colors.white,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  final company =
                                      vehicle['company'] ??
                                      vehicle['companyName'];
                                  if (company != null &&
                                      company.toString().isNotEmpty) {
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_outline, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      "Check In",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _showEditVehicleDialog(
                                        context,
                                        vehicle,
                                      ),
                                  icon: Image.asset(
                                    'assets/icons/edit_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text("Edit"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.infoColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _showDeleteDialog(context, vehicle),
                                  icon: Image.asset(
                                    'assets/icons/delete_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text("Delete"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.dangerColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
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
            loading:
                () =>
                    state.isOperationLoading
                        ? const SizedBox.shrink()
                        : const AppLoadingWidget(),
            error:
                (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry:
                      () => ref.read(securityProvider.notifier).fetchVehicles(),
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              onPressed: () => _showAddVehicleDialog(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/car_icon.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Add Vehicle",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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
              labelText: "Search Vehicles",
              hintText: "Search Vehicles",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              labelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              floatingLabelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 20,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                    icon: Image.asset(
                      'assets/icons/qr_scan_icon.png',
                      width: 24,
                      height: 24,
                    ),
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
              ),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: checkedIn.length,
                itemBuilder: (context, index) {
                  final vehicle = checkedIn[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/icons/car_icon.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Number: ${vehicle['vehicleNumber'] ?? ''}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      "Driver: ${vehicle['driverName'] ?? ''}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.dangerColor,
                                  foregroundColor: Colors.white,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_outline, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      "Check Out",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _showEditVehicleDialog(
                                        context,
                                        vehicle,
                                      ),
                                  icon: Image.asset(
                                    'assets/icons/edit_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text("Edit"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.infoColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _showDeleteDialog(context, vehicle),
                                  icon: Image.asset(
                                    'assets/icons/delete_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text("Delete"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.dangerColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
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
            loading:
                () =>
                    state.isOperationLoading
                        ? const SizedBox.shrink()
                        : const AppLoadingWidget(),
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

  // IconData _getVehicleIcon(String? type) {
  //   switch (type) {
  //     case 'CAR':
  //       return Icons.directions_car;
  //     case 'BIKE':
  //       return Icons.motorcycle;
  //     case 'TRUCK':
  //       return Icons.local_shipping;
  //     default:
  //       return Icons.minor_crash;
  //   }
  // }

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
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  title: const Text(
                    "New Vehicle Entry",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                          TextFormField(
                            controller: numberController,
                            decoration: InputDecoration(
                              labelText: "Vehicle Number",
                              hintText: "e.g. TN01AB1234",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: driverController,
                            decoration: InputDecoration(
                              labelText: "Driver Name",
                              hintText: "Driver Name",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
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
                          const SizedBox(height: 16),
                          FormField<String>(
                            initialValue: selectedType,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<String>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedType,
                                    label: const Text(
                                      "Type",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    hintText: "Select Type",
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        selectedType == "CAR"
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
                                            vertical: 16,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
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
                                        ["CAR", "BIKE", "TRUCK", "OTHER"].map((
                                          t,
                                        ) {
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
                                      setDialogState(() => selectedType = v);
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
                          const SizedBox(height: 16),
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
                                    hintText: "Select Purpose",
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
                                            case "Guest":
                                              return 'assets/icons/visitor_icon.png';
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
                                            vertical: 16,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
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
                                        [
                                          "Employee",
                                          "Visitor",
                                          "Delivery",
                                          "Vendor",
                                          "Guest",
                                        ].map((p) {
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
                                            case "Guest":
                                              assetPath =
                                                  'assets/icons/visitor_icon.png';
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
                                      setDialogState(() => selectedPurpose = v);
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
                          const SizedBox(height: 16),
                          FormField<int>(
                            initialValue: selectedTenantId,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<int>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedTenantId,
                                    label: const Text(
                                      "Select Company",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    hintText: "Select Company",
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
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
                                        state.tenants
                                            .map(
                                              (t) => DropdownMenuEntry<int>(
                                                value: t['id'] as int,
                                                label:
                                                    (t['company'] ??
                                                            t['companyName'] ??
                                                            'No Name')
                                                        .toString(),
                                              ),
                                            )
                                            .toList(),
                                    onSelected: (v) {
                                      setDialogState(
                                        () => selectedTenantId = v,
                                      );
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
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
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
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  title: const Text(
                    "Edit Vehicle",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                          TextFormField(
                            controller: numberController,
                            decoration: InputDecoration(
                              labelText: "Vehicle Number",
                              hintText: "e.g. TN01AB1234",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: driverController,
                            decoration: InputDecoration(
                              labelText: "Driver Name",
                              hintText: "Driver Name",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
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
                          const SizedBox(height: 16),
                          FormField<String>(
                            initialValue: selectedType,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<String>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedType,
                                    label: const Text(
                                      "Type",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    hintText: "Select Type",
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        selectedType == "CAR"
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
                                            vertical: 16,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
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
                                        ["CAR", "BIKE", "TRUCK", "OTHER"].map((
                                          t,
                                        ) {
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
                                      setDialogState(() => selectedType = v);
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
                          const SizedBox(height: 16),
                          FormField<int>(
                            initialValue: selectedTenantId,
                            validator: (v) => v == null ? "Required" : null,
                            builder: (fieldState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownMenu<int>(
                                    width: double.infinity,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedTenantId,
                                    label: const Text(
                                      "Select Company",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    hintText: "Select Company",
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
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
                                        state.tenants
                                            .map(
                                              (t) => DropdownMenuEntry<int>(
                                                value: t['id'] as int,
                                                label:
                                                    (t['company'] ??
                                                            t['companyName'] ??
                                                            'No Name')
                                                        .toString(),
                                              ),
                                            )
                                            .toList(),
                                    onSelected: (v) {
                                      setDialogState(
                                        () => selectedTenantId = v,
                                      );
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
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
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
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/delete_icon.png',
                  width: 60,
                  height: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Delete Vehicle",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to delete ${vehicle['vehicleNumber']}?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final success = await ref
                              .read(securityProvider.notifier)
                              .deleteVehicle(vehicle['id']);
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              SnackbarUtils.showSuccess(
                                context,
                                "Vehicle Deleted",
                              );
                            } else {
                              SnackbarUtils.showError(context, "Delete Failed");
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
            actions:
                [], // Actions are part of content for better layout control
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
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                  hintText: "Select Purpose",
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
                                          case "Guest":
                                            return 'assets/icons/visitor_icon.png';
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
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
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
                                      [
                                        "Employee",
                                        "Visitor",
                                        "Delivery",
                                        "Vendor",
                                        "Guest",
                                      ].map((p) {
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
                                          case "Guest":
                                            assetPath =
                                                'assets/icons/visitor_icon.png';
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
                                    setDialogState(() => selectedPurpose = v);
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
                        const SizedBox(height: 16),
                        FormField<int>(
                          initialValue: selectedTenantId,
                          validator: (v) => v == null ? "Required" : null,
                          builder: (fieldState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownMenu<int>(
                                  width: double.infinity,
                                  expandedInsets: EdgeInsets.zero,
                                  initialSelection: selectedTenantId,
                                  label: const Text(
                                    "Select Company",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  hintText: "Select Company",
                                  inputDecorationTheme: InputDecorationTheme(
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
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
                                      state.tenants
                                          .map(
                                            (t) => DropdownMenuEntry<int>(
                                              value: t['id'] as int,
                                              label:
                                                  (t['company'] ??
                                                          t['companyName'] ??
                                                          'No Name')
                                                      .toString(),
                                            ),
                                          )
                                          .toList(),
                                  onSelected: (v) {
                                    setDialogState(() => selectedTenantId = v);
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
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
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
        _buildHistoryDateFilter(),
        Expanded(
          child: state.vehicleReports.when(
            data: (history) {
              if (history.isEmpty) {
                return const Center(child: Text("No history found"));
              }

              // Sort by check-in time descending (latest first)
              final sortedHistory = List.from(history);
              sortedHistory.sort((a, b) {
                final aTime =
                    a['checkInTime'] != null
                        ? DateTime.parse(a['checkInTime'])
                        : DateTime(2000);
                final bTime =
                    b['checkInTime'] != null
                        ? DateTime.parse(b['checkInTime'])
                        : DateTime(2000);
                return bTime.compareTo(aTime);
              });

              return RefreshIndicator(
                onRefresh:
                    () => ref
                        .read(securityProvider.notifier)
                        .fetchVehicleReports(
                          _historyStartDate,
                          _historyEndDate,
                        ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sortedHistory.length,
                  itemBuilder: (context, index) {
                    final vehicle = sortedHistory[index];
                    final checkInTime =
                        vehicle['checkInTime'] != null
                            ? DateTime.parse(vehicle['checkInTime'])
                            : null;
                    final checkOutTime =
                        vehicle['checkOutTime'] != null
                            ? DateTime.parse(vehicle['checkOutTime'])
                            : null;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Car Icon
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/icons/car_icon.png',
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Vehicle Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Vehicle Number
                                  Text(
                                    vehicle['vehicleNumber'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Driver Name
                                  Text(
                                    "${vehicle['driverName'] ?? 'N/A'}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right side - Check-in/Check-out status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Company Name
                                Text(
                                  "Company: ${vehicle['company'] ?? vehicle['companyName'] ?? 'N/A'}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Check-in status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    checkInTime != null
                                        ? _formatDateTime(
                                          vehicle['checkInTime'],
                                        )
                                        : 'N/A',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Check-out status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        checkOutTime != null
                                            ? Colors.red.shade50
                                            : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    checkOutTime != null
                                        ? _formatDateTime(
                                          vehicle['checkOutTime'],
                                        )
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          checkOutTime != null
                                              ? Colors.red.shade700
                                              : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
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
                ),
              );
            },
            loading: () => const AppLoadingWidget(),
            error:
                (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry:
                      () => ref
                          .read(securityProvider.notifier)
                          .fetchVehicleReports(
                            _historyStartDate,
                            _historyEndDate,
                          ),
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

  Widget _buildHistoryDateFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectHistoryDate(context, true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FROM",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(_historyStartDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          Expanded(
            child: InkWell(
              onTap: () => _selectHistoryDate(context, false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "TO",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(_historyEndDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
