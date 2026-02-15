// ignore_for_file: unnecessary_null_comparison

import 'package:ceedeeyes/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../model/security_state.dart';
import '../model/staff_model.dart';
import '../provider/security_provider.dart';

class StaffEntryScreen extends ConsumerStatefulWidget {
  const StaffEntryScreen({super.key});

  @override
  ConsumerState<StaffEntryScreen> createState() => _StaffEntryScreenState();
}

class _StaffEntryScreenState extends ConsumerState<StaffEntryScreen> {
  final _checkInSearchController = TextEditingController();
  final _employeeController = TextEditingController();
  final _vendorController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _otherController = TextEditingController();
  final _visitorController = TextEditingController();
  final _checkOutSearchController = TextEditingController();
  String _checkInSearchQuery = "";
  String _checkOutSearchQuery = "";

  DateTime _historyStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _historyEndDate = DateTime.now();
  final vehicleHistoryScrollController = ScrollController();
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(securityProvider.notifier).fetchStaffs();
      ref
          .read(securityProvider.notifier)
          .fetchStaffReports(_historyStartDate, _historyEndDate);
    });
    vehicleHistoryScrollController.addListener(_staffHistoryScrollListener);
  }

  @override
  void dispose() {
    _checkInSearchController.dispose();
    _employeeController.dispose();
    _vendorController.dispose();
    _deliveryController.dispose();
    _otherController.dispose();
    _visitorController.dispose();
    _checkOutSearchController.dispose();
    vehicleHistoryScrollController.dispose();
    super.dispose();
  }

  void _staffHistoryScrollListener() {
    if (vehicleHistoryScrollController.position.pixels >=
        vehicleHistoryScrollController.position.maxScrollExtent - 200) {
      ref
          .read(securityProvider.notifier)
          .fetchStaffReports(
            _historyStartDate,
            _historyEndDate,
            isLoadMore: true,
          );
      logger.d("Loading more staff history...");
    }
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
          .fetchStaffReports(_historyStartDate, _historyEndDate);
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
                "Staff Management",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    ref.read(securityProvider.notifier).fetchStaffs();

                    ref
                        .read(securityProvider.notifier)
                        .fetchStaffReports(_historyStartDate, _historyEndDate);
                  },
                  icon: Icon(Icons.refresh),
                ),
              ],
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
    if (state.isStaffLoading) {
      return const Center(child: AppLoadingWidget());
    }

    if (state.staffError != null) {
      return Center(
        child: AppErrorWidget(
          message: state.staffError!,
          onRetry: () => ref.read(securityProvider.notifier).fetchStaffs(),
        ),
      );
    }

    final filtered =
        state.staffs
            .where((v) => v.status != 'CHECKED_IN')
            .where(
              (v) => v.employeeId.toString().toLowerCase().contains(
                _checkInSearchQuery.toLowerCase(),
              ),
            )
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _checkInSearchController,
            decoration: InputDecoration(
              labelText: "Search Staff",
              hintText: "Search Staff",
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
                        validator: (v) => v['status'] == 'CHECKED_OUT',
                        invalidMessage: "Staff is NOT Checked Out",
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _checkInSearchController.text = result;
                          _checkInSearchQuery = result;
                        });
                        SnackbarUtils.showSuccess(context, "Staff Found");
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
        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                "No staffs found",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final staff = filtered[index];
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
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade50,
                          child: Center(
                            child: Text(
                              staff.staffName.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Staff Name : ",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    staff.staffName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Emp Id : ",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    staff.employeeId,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onPressed:
                              state.isOperationLoading
                                  ? null
                                  : () async {
                                    final success = await ref
                                        .read(securityProvider.notifier)
                                        .staffCheckIn(staff.id);

                                    if (context.mounted) {
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
                                  },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCheckOutTab(SecurityState state) {
    if (state.isStaffLoading) {
      return const Center(child: AppLoadingWidget());
    }

    if (state.staffError != null) {
      return Center(
        child: AppErrorWidget(
          message: state.staffError!,
          onRetry: () => ref.read(securityProvider.notifier).fetchStaffs(),
        ),
      );
    }

    final checkedIn =
        state.staffs
            .where((v) => v.status == 'CHECKED_IN')
            .where(
              (v) => v.employeeId.toString().toLowerCase().contains(
                _checkOutSearchQuery.toLowerCase(),
              ),
            )
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _checkOutSearchController,
            decoration: InputDecoration(
              labelText: "Search Staff",
              hintText: "Search Staff",
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
                        invalidMessage: "Staff is NOT Checked In",
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _checkOutSearchController.text = result;
                          _checkOutSearchQuery = result;
                        });
                        SnackbarUtils.showSuccess(context, "Staff Found");
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
          child: Builder(
            builder: (context) {
              if (checkedIn.isEmpty) {
                return const Center(child: Text("No matching staffs inside"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: checkedIn.length,
                itemBuilder: (context, index) {
                  final staff = checkedIn[index];
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade50,
                                child: Center(
                                  child: Text(
                                    staff.staffName.substring(0, 1),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Staff Name : ",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          staff.staffName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Text(
                                          "Emp Id : ",
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        Text(
                                          staff.employeeId,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
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
                                onPressed:
                                    state.isOperationLoading
                                        ? null
                                        : () async {
                                          final success = await ref
                                              .read(securityProvider.notifier)
                                              .staffCheckOut(staff.id);
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.logout, size: 18),
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(SecurityState state) {
    return Column(
      children: [
        _buildHistoryDateFilter(),
        Expanded(
          child: state.staffReports.when(
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
                        .fetchStaffReports(_historyStartDate, _historyEndDate),
                child: ListView.builder(
                  controller: vehicleHistoryScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount:
                      sortedHistory.length +
                      (ref.watch(securityProvider).hasMoreStaffs ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == sortedHistory.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      );
                    }
                    final staff = sortedHistory[index];
                    final checkInTime =
                        staff['checkInTime'] != null
                            ? DateTime.parse(staff['checkInTime'])
                            : null;
                    final checkOutTime =
                        staff['checkOutTime'] != null
                            ? DateTime.parse(staff['checkOutTime'])
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
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Staff Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff['name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Emp Id: ${staff['employeeCode'] ?? 'N/A'}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
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
                                        ? _formatDateTime(staff['checkInTime'])
                                        : 'N/A',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                                        ? _formatDateTime(staff['checkOutTime'])
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
                          .fetchStaffReports(
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
                  "Scan Staff QR",
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

                            StaffModel? staff;
                            try {
                              staff = state.staffs.firstWhere(
                                (s) =>
                                    s.employeeId.toString().toLowerCase() ==
                                    code.toLowerCase(),
                              );
                            } catch (_) {}

                            if (staff != null) {
                              if (validator != null &&
                                  !validator({'status': staff.status})) {
                                Navigator.pop(sheetContext);
                                SnackbarUtils.showError(
                                  context,
                                  invalidMessage ?? "Invalid staff status",
                                );
                              } else {
                                Navigator.pop(sheetContext, code);
                              }
                            } else {
                              Navigator.pop(sheetContext);
                              SnackbarUtils.showError(
                                context,
                                "Please scan a valid Staff QR",
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

  // Future<void> _pickAddressProofImage(StateSetter setDialogState) async {
  //   try {
  //     final XFile? image = await _picker.pickImage(
  //       source: ImageSource.camera,
  //       imageQuality: 50,
  //       maxWidth: 800,
  //     );
  //     if (image != null) {
  //       final bytes = await image.readAsBytes();
  //       final base64String = base64Encode(bytes);
  //       setDialogState(() {
  //         _addressProofImage64 = base64String;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error picking image: $e");
  //   }
  // }
}
