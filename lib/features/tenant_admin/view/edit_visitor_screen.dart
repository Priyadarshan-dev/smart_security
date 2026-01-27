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

  final List<String> _visitTypes = [
    "Interview",
    "Visitor",
    "Vendor",
    "Delivery",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.visitor['visitorName'],
    );
    _mobileController = TextEditingController(
      text: widget.visitor['mobileNumber'],
    );

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
    const primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Visitor"),
        centerTitle: true,
        backgroundColor: const Color(0xFF60A5FA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Visitor Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Visitor Name",
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: "Enter Visitor Name",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  if (RegExp(r'[0-9]').hasMatch(v))
                    return "Numbers not allowed";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Mobile Number
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: "Enter Mobile Number",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                ),
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
              const SizedBox(height: 24),
              // Visit Type Dropdown
              FormField<String>(
                initialValue: _selectedVisitType,
                validator: (v) => v == null ? "Required" : null,
                builder: (fieldState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownMenu<String>(
                        width: double.infinity,
                        expandedInsets: EdgeInsets.zero,
                        initialSelection: _selectedVisitType,
                        label: const Text(
                          "Visit Type",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        hintText: "Select Visit Type",
                        leadingIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            _selectedVisitType == null
                                ? 'assets/icons/other_icon.png'
                                : (() {
                                  switch (_selectedVisitType) {
                                    case "Interview":
                                      return 'assets/icons/interview_icon.png';
                                    case "Visitor":
                                      return 'assets/icons/visitor_icon.png';
                                    case "Vendor":
                                      return 'assets/icons/vendor_icon.png';
                                    case "Delivery":
                                      return 'assets/icons/delivery_icon.png';
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
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        dropdownMenuEntries:
                            _visitTypes.map((t) {
                              String assetPath;
                              switch (t) {
                                case "Interview":
                                  assetPath = 'assets/icons/interview_icon.png';
                                  break;
                                case "Visitor":
                                  assetPath = 'assets/icons/visitor_icon.png';
                                  break;
                                case "Vendor":
                                  assetPath = 'assets/icons/vendor_icon.png';
                                  break;
                                case "Delivery":
                                  assetPath = 'assets/icons/delivery_icon.png';
                                  break;
                                default:
                                  assetPath = 'assets/icons/other_icon.png';
                              }
                              return DropdownMenuEntry<String>(
                                value: t,
                                label: t,
                                leadingIcon: Image.asset(
                                  assetPath,
                                  width: 24,
                                  height: 24,
                                ),
                              );
                            }).toList(),
                        onSelected: (v) {
                          setState(() => _selectedVisitType = v);
                          fieldState.didChange(v);
                        },
                      ),
                      if (fieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 6),
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
              const SizedBox(height: 24),
              // Visit Date
              TextFormField(
                readOnly: true,
                onTap: () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _visitDate.isBefore(today) ? today : _visitDate,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: primaryColor,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _visitDate = picked);
                },
                decoration: InputDecoration(
                  labelText: "Visit Date",
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: "Select Date",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixIcon: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.grey,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                ),
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(_visitDate),
                ),
              ),
              const SizedBox(height: 48),
              // Update Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60A5FA), // Refined blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      state.isOperationLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await ref
                                  .read(tenantAdminProvider.notifier)
                                  .updateVisitor(widget.visitor['id'], {
                                    "visitorName": _nameController.text,
                                    "mobileNumber": _mobileController.text,
                                    "visitDate": DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_visitDate),
                                    "visitType": _selectedVisitType,
                                  });
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
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "UPDATE VISITOR",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
