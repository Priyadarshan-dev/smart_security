import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/security_controller.dart';

class VehicleEntryScreen extends ConsumerStatefulWidget {
  const VehicleEntryScreen({super.key});

  @override
  ConsumerState<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends ConsumerState<VehicleEntryScreen> {
  final _numberController = TextEditingController();
  final _driverController = TextEditingController();
  String? _selectedVehicleType;
  String? _selectedPurpose;
  int? _selectedTenantId;
  List<dynamic> _tenants = [];

  final List<String> _vehicleTypes = ["CAR", "BIKE", "TRUCK", "OTHER"];
  final List<String> _purposes = [
    "Visitor",
    "Delivery",
    "Vendor",
    "Interview",
    "Guest",
  ];

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    final list = await ref.read(securityProvider.notifier).fetchTenants();
    if (mounted) setState(() => _tenants = list);
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Management")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _driverController,
                decoration: const InputDecoration(
                  labelText: "Driver Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                items:
                    _vehicleTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedVehicleType = v),
                decoration: const InputDecoration(
                  labelText: "Vehicle Type",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? "Required" : null,
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
                  labelText: "Select Company (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final success = await ref
                              .read(securityProvider.notifier)
                              .vehicleEntry({
                                "vehicleNumber": _numberController.text,
                                "driverName": _driverController.text,
                                "vehicleType": _selectedVehicleType,
                                "purpose": _selectedPurpose,
                                "tenantId": _selectedTenantId,
                              });
                          if (success) Navigator.pop(context);
                        }
                      },
                      child: const Text("CHECK-IN"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () async {
                        if (_numberController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Enter Vehicle Number"),
                            ),
                          );
                          return;
                        }
                        final success = await ref
                            .read(securityProvider.notifier)
                            .vehicleExit(_numberController.text);
                        if (success) Navigator.pop(context);
                      },
                      child: const Text("CHECK-OUT"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
