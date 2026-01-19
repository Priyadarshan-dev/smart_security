import 'dart:convert';
import 'package:flutter/material.dart';
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
            appBar: AppBar(
              title: const Text("Visitor Management"),
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                indicatorColor: Colors.white,
                tabs: const [Tab(text: "Scheduled"), Tab(text: "Walk-in")],
              ),
            ),
            body: TabBarView(
              children: [
                _buildScheduledTab(state.todayVisitors),
                _buildWalkInTab(state),
              ],
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

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      item['imageUrl'] != null
                          ? MemoryImage(base64Decode(item['imageUrl']))
                          : null,
                  child:
                      item['imageUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                ),
                title: Text(item['visitorName']),
                subtitle: Text("${item['mobileNumber']} • ${item['status']}"),
                trailing:
                    isAllowed
                        ? ElevatedButton(
                          onPressed:
                              () => ref
                                  .read(securityProvider.notifier)
                                  .checkInVisitor(item['id']),
                          child: const Text("Check-In"),
                        )
                        : (isPending
                            ? ElevatedButton(
                              onPressed: null, // Disabled until allowed
                              child: const Text("Pending"),
                            )
                            : Text(item['status'] ?? "Unknown")),
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
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
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
              decoration: const InputDecoration(
                labelText: "Mobile Number",
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: "Visitor Name",
                border: OutlineInputBorder(),
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
                  _purposes
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
              onChanged: (v) => setState(() => _selectedPurpose = v),
              decoration: const InputDecoration(
                labelText: "Visit Type",
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: "Select Company",
                border: OutlineInputBorder(),
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
                padding: const EdgeInsets.all(16),
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
                        "assignedAdmins": _selectedAdminIds,
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
      }
    }
  }
}
