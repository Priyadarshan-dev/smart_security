import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/tenant_admin_controller.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_utils.dart';

class AddVisitorScreen extends ConsumerStatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  ConsumerState<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends ConsumerState<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedVisitType = "Interview";
  DateTime _visitDate = DateTime.now();

  final List<String> _visitTypes = [
    "Interview",
    "Visitor",
    "Vendor",
    "Delivery",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantAdminProvider);
    const primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text("Schedule Visitor"),
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
                    vertical: 12,
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
                    vertical: 12,
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
              DropdownButtonFormField<String>(
                value: _selectedVisitType,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                isDense: true,
                selectedItemBuilder: (context) {
                  return _visitTypes.map((t) {
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
                    return Row(
                      children: [
                        Image.asset(assetPath, width: 24, height: 24),
                        const SizedBox(width: 12),
                        Text(t),
                      ],
                    );
                  }).toList();
                },
                decoration: InputDecoration(
                  labelText: "Visit Type",
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: "Select Visit Type",
                  prefixIcon:
                      _selectedVisitType == null
                          ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/icons/other_icon.png',
                              width: 24,
                              height: 24,
                            ),
                          )
                          : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 15,
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
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                ),
                items:
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
                      return DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Image.asset(assetPath, width: 24, height: 24),
                            const SizedBox(width: 12),
                            Text(t),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (v) => setState(() => _selectedVisitType = v),
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
                    vertical: 12,
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
              // Schedule Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF60A5FA,
                    ), // Matches new theme
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
                                  .scheduleVisitor({
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
                                    "Visitor scheduled successfully",
                                  );
                                  Navigator.pop(context);
                                } else {
                                  SnackbarUtils.showError(
                                    context,
                                    "Failed to schedule visitor",
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
                            "SCHEDULE VISITOR",
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
