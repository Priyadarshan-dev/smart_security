import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/tenant_admin_controller.dart';
import 'package:intl/intl.dart';

class AddVisitorScreen extends ConsumerStatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  ConsumerState<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends ConsumerState<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedVisitType = "GUEST";
  String? _selectedPurpose;
  DateTime _visitDate = DateTime.now();

  final List<String> _visitTypes = [
    "GUEST",
    "VENDOR",
    "DELIVERY",
    "INTERVIEW",
    "OTHER",
  ];
  final List<String> _purposes = [
    "Visitor",
    "Office Meeting",
    "Project Discussion",
    "Maintenance",
    "Emergency",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Visitor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Visitor Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
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
              DropdownButtonFormField<String>(
                value: _selectedVisitType,
                items:
                    _visitTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedVisitType = v),
                decoration: const InputDecoration(
                  labelText: "Visit Type",
                  border: OutlineInputBorder(),
                ),
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
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(_visitDate)}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _visitDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setState(() => _visitDate = picked);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      _selectedPurpose != null) {
                    final success = await ref
                        .read(tenantAdminProvider.notifier)
                        .scheduleVisitor({
                          "visitorName": _nameController.text,
                          "mobileNumber": _mobileController.text,
                          "visitDate": DateFormat(
                            'yyyy-MM-dd',
                          ).format(_visitDate),
                          "purpose": _selectedPurpose,
                          "visitType": _selectedVisitType,
                        });
                    if (success) Navigator.pop(context);
                  } else if (_selectedPurpose == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a purpose")),
                    );
                  }
                },
                child: const Text("SCHEDULE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
