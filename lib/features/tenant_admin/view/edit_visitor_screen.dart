import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/tenant_admin_controller.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_utils.dart';

class EditVisitorScreen extends ConsumerStatefulWidget {
  final dynamic visitor;
  const EditVisitorScreen({super.key, required this.visitor});

  @override
  ConsumerState<EditVisitorScreen> createState() => _EditVisitorScreenState();
}

class _EditVisitorScreenState extends ConsumerState<EditVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late String? _selectedVisitType;
  late DateTime _visitDate;

  final List<String> _visitTypes = ["Interview",
    "Visitor",
    "Vendor",
    "Delivery",
    "Other",];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.visitor['visitorName']);
    _mobileController = TextEditingController(text: widget.visitor['mobileNumber']);
    
    // Defensive value handling for DropdownButton
    final String? incomingType = widget.visitor['visitType']?.toString();
    if (_visitTypes.contains(incomingType)) {
      _selectedVisitType = incomingType;
    } else {
      _selectedVisitType = "Other";
    }

    try {
      _visitDate = DateFormat('yyyy-MM-dd').parse(widget.visitor['visitDate']);
    } catch (_) {
      _visitDate = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Visitor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Visitor Name", border: OutlineInputBorder()),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  if (RegExp(r'[0-9]').hasMatch(v)) return "Numbers not allowed";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  if (v.length != 10) return "Must be 10 digits";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVisitType,
                items: _visitTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedVisitType = v),
                decoration: const InputDecoration(labelText: "Visit Type", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: Text("Date: ${DateFormat('yyyy-MM-dd').format(_visitDate)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _visitDate.isBefore(today) ? today : _visitDate,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _visitDate = picked);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: state.isOperationLoading
                    ? null
                    : () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await ref
                            .read(tenantAdminProvider.notifier)
                            .updateVisitor(
                              widget.visitor['id'],
                              {
                                "visitorName": _nameController.text,
                                "mobileNumber": _mobileController.text,
                                "visitDate": DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_visitDate),
                                "visitType": _selectedVisitType,
                              },
                            );
                        if (context.mounted) {
                          if (success) {
                            SnackbarUtils.showSuccess(
                              context,
                              "Visitor updated successfully",
                            );
                            Navigator.pop(context);
                          } else {
                            SnackbarUtils.showError(
                              context,
                              "Failed to update visitor",
                            );
                          }
                        }
                      }
                    },
                child:
                    state.isOperationLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text("UPDATE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
