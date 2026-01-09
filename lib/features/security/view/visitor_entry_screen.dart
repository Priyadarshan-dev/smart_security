import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/security_controller.dart';

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
  List<dynamic> _tenants = [];

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
      _loadTenants();
    });
  }

  Future<void> _loadTenants() async {
    final list = await ref.read(securityProvider.notifier).fetchTenants();
    if (mounted) setState(() => _tenants = list);
  }

  @override
  Widget build(BuildContext context) {
    final visitors = ref.watch(securityProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Visitor Management"),
          bottom: const TabBar(
            tabs: [Tab(text: "Scheduled"), Tab(text: "Walk-in")],
          ),
        ),
        body: TabBarView(
          children: [_buildScheduledTab(visitors), _buildWalkInTab()],
        ),
      ),
    );
  }

  Widget _buildScheduledTab(AsyncValue<List<dynamic>> visitors) {
    return visitors.when(
      data: (list) {
        final pending = list.where((v) => v['status'] != 'CHECKED_IN').toList();
        if (pending.isEmpty) {
          return const Center(
            child: Text(
              "No scheduled visitors found for today",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final item = pending[index];
            return ListTile(
              title: Text(item['visitorName']),
              subtitle: Text(item['mobileNumber']),
              trailing: ElevatedButton(
                onPressed:
                    () => ref
                        .read(securityProvider.notifier)
                        .checkInVisitor(item['id']),
                child: const Text("Check-In"),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildWalkInTab() {
    final formKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: "Mobile Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Visitor Name",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
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
                labelText: "Purpose",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null ? "Required" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedTenantId,
              items:
                  _tenants
                      .map(
                        (t) => DropdownMenuItem(
                          value: t['id'] as int,
                          child: Text(t['companyName']),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedTenantId = v),
              decoration: const InputDecoration(
                labelText: "Select Company",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null ? "Required" : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await ref
                      .read(securityProvider.notifier)
                      .addWalkIn({
                        "visitorName": _nameController.text,
                        "mobileNumber": _mobileController.text,
                        "purpose": _selectedPurpose,
                        "tenantIds": [_selectedTenantId],
                      });
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Approval Request Sent")),
                    );
                    Navigator.pop(context);
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
}
