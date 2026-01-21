import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ceedeeyes/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/security_controller.dart';
import '../../../core/utils/snackbar_utils.dart';

class VisitorEntryScreen extends ConsumerStatefulWidget {
  const VisitorEntryScreen({super.key});

  @override
  ConsumerState<VisitorEntryScreen> createState() => _VisitorEntryScreenState();
}

class _VisitorEntryScreenState extends ConsumerState<VisitorEntryScreen> {
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedPurpose;
  int? _selectedTenantId;
  String? _selectedCompany;
  final List<int> _selectedAdminIds = [];
  String? _image64;
  final ImagePicker _picker = ImagePicker();

  final List<String> _purposes = [
    "Visitor",
    "Interview",
    "Vendor",
    "Delivery",
    "Guest",
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(securityProvider.notifier).fetchTodayVisitors();
      ref.read(securityProvider.notifier).fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);

    return Stack(
      children: [
        DefaultTabController(
          length: 2,
          child: Scaffold(
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
                "Visitor Management",
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
                        Tab(text: "Scheduled"),
                        Tab(text: "Walk-in"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildScheduledTab(state.todayVisitors),
                        _buildWalkInTab(state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.isOperationLoading)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduledTab(AsyncValue<List<dynamic>> visitors) {
    return visitors.when(
      data: (list) {
        final visibleVisitors =
            list
                .where(
                  (v) =>
                      v['status'] != 'CHECKED_IN' &&
                      v['status'] != 'REJECTED' &&
                      v['status'] != 'CHECKED_OUT',
                )
                .toList();

        if (visibleVisitors.isEmpty) {
          return const Center(
            child: Text(
              "No scheduled visitors found for today",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh:
              () => ref.read(securityProvider.notifier).fetchTodayVisitors(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: visibleVisitors.length,
            itemBuilder: (context, index) {
              final item = visibleVisitors[index];
              final bool isAllowed =
                  item['status'] == 'ALLOWED' || item['status'] == 'APPROVED';
              final bool isPending = item['status'] == 'PENDING';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                item['imageUrl'] != null
                                    ? MemoryImage(
                                      base64Decode(item['imageUrl']),
                                    )
                                    : null,
                            child:
                                item['imageUrl'] == null
                                    ? const Icon(Icons.person, size: 30)
                                    : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['visitorName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "+91 ${item['mobileNumber'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAllowed)
                            ElevatedButton(
                              onPressed:
                                  () => ref
                                      .read(securityProvider.notifier)
                                      .checkInVisitor(item['id']),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle_outline, size: 18),
                                  SizedBox(width: 4),
                                  Text("Check-In"),
                                ],
                              ),
                            )
                          else if (isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Pending",
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['visitType'] ?? item['purpose'] ?? 'Visitor',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildWalkInTab(SecurityState state) {
    final formKey = GlobalKey<FormState>();

    final selectedTenant = state.tenants.firstWhere(
      (t) => t['id'] == _selectedTenantId,
      orElse: () => null,
    );
    final admins =
        selectedTenant != null ? selectedTenant['admins'] as List<dynamic> : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlue, width: 2.5),
                  ),
                  child:
                      _image64 != null
                          ? ClipOval(
                            child: Image.memory(
                              base64Decode(_image64!),
                              fit: BoxFit.cover,
                            ),
                          )
                          : Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "Capture Visitor Photo",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _mobileController,
              decoration: InputDecoration(
                labelText: "Mobile Number",
                hintText: "Mobile Number",
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
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return "Required";
                if (v.length != 10) return "Must be 10 digits";
                if (!RegExp(r'^[0-9]+$').hasMatch(v)) return "Numbers only";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Visitor Name",
                hintText: "Visitor Name",
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return "Required";
                if (v.length < 3) return "Too short";
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPurpose,
              items:
                  _purposes.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
              onChanged: (v) => setState(() => _selectedPurpose = v),
              decoration: InputDecoration(
                labelText: "Visit Type",
                hintText: "Select Type",
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              validator: (v) => v == null ? "Required" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedTenantId,
              items:
                  state.tenants.map((t) {
                    print("Dropdown List Item: ${t['companyName']}");
                    return DropdownMenuItem(
                      value: t['id'] as int,
                      child: Text(
                        (t['company'] ?? t['companyName'] ?? 'No Name')
                            .toString(),
                      ),
                    );
                  }).toList(),
              onChanged: (v) {
                final tenant = state.tenants.firstWhere((t) => t['id'] == v);
                setState(() {
                  _selectedTenantId = v;
                  _selectedCompany = tenant['company'] ?? tenant['companyName'];
                  _selectedAdminIds.clear();
                });
              },
              decoration: InputDecoration(
                labelText: "Select Company",
                hintText: "Select Company",
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              validator: (v) => v == null ? "Required" : null,
            ),
            const SizedBox(height: 16),
            if (admins.isNotEmpty) ...[
              const Text(
                "Select Admins",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...admins.map((admin) {
                final adminId = admin['id'] as int;
                final isSelected = _selectedAdminIds.contains(adminId);
                return CheckboxListTile(
                  title: Text(
                    admin['fullName'] ?? admin['username'] ?? 'Admin',
                  ),
                  subtitle: Text(admin['email'] ?? ''),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedAdminIds.add(adminId);
                      } else {
                        _selectedAdminIds.remove(adminId);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
              if (_selectedAdminIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    "Please select at least one admin",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ] else if (_selectedTenantId != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  "No admins found for this company",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    _selectedAdminIds.isNotEmpty) {
                  final success = await ref
                      .read(securityProvider.notifier)
                      .addWalkIn({
                        "visitorName": _nameController.text,
                        "mobileNumber": _mobileController.text,
                        "visitType": _selectedPurpose,
                        "company": _selectedCompany,
                        "tenantId": _selectedTenantId,
                        "assignedAdminIds": _selectedAdminIds,
                        "imageUrl": _image64,
                      });
                  if (context.mounted) {
                    if (success) {
                      SnackbarUtils.showSuccess(
                        context,
                        "Approval Request Sent",
                      );
                      Navigator.pop(context);
                    } else {
                      SnackbarUtils.showError(
                        context,
                        "Failed to send request",
                      );
                    }
                  }
                }
              },
              child: const Text("REQUEST APPROVAL"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _image64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, "Error capturing image");
        print("Error While Capturing Image ${e.toString()}");
      }
    }
  }
}
