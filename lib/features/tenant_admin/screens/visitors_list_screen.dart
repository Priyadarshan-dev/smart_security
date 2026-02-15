import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/tenant_admin_state.dart';
import '../provider/tenant_admin_provider.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../../core/widgets/app_error_widget.dart';
import 'edit_visitor_screen.dart';
import '../../../core/utils/snackbar_utils.dart';

class VisitorsListScreen extends ConsumerStatefulWidget {
  const VisitorsListScreen({super.key});

  @override
  ConsumerState<VisitorsListScreen> createState() => _VisitorsListScreenState();
}

class _VisitorsListScreenState extends ConsumerState<VisitorsListScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantAdminProvider);
    final visitorsAsync = state.allVisitors;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitors"),
        centerTitle: true,
        backgroundColor: const Color(0xFF60A5FA),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tenantAdminProvider.notifier).fetchAllVisitors();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh:
                () => ref.read(tenantAdminProvider.notifier).fetchAllVisitors(),
            child: visitorsAsync.when(
              data: (visitors) {
                if (visitors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Color(0xFFF1F5F9),
                        ),
                        const SizedBox(height: 16),
                        const Text("No visitors found"),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final visitor = visitors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Visitor Icon
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _safeImage(
                                    visitor['imageUrl'],
                                  ),
                                  child:
                                      _safeImage(visitor['imageUrl']) == null
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                ),
                                const SizedBox(width: 20),
                                // Visitor Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Name: ${visitor['visitorName'] ?? 'N/A'}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Mobile
                                      Text(
                                        "Mobile: ${visitor['mobileNumber'] ?? 'N/A'}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Purpose / Visit Type
                                      Text(
                                        "Purpose: ${visitor['visitType'] ?? 'N/A'}${visitor['comments'] != null && visitor['comments'].toString().isNotEmpty ? " / ${visitor['comments']}" : ""}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Date
                                      Text(
                                        "Date: ${visitor['visitDate'] ?? 'N/A'}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        state.isOperationLoading
                                            ? null
                                            : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => EditVisitorScreen(
                                                      visitor: visitor,
                                                    ),
                                              ),
                                            ),
                                    icon: Image.asset(
                                      'assets/icons/edit_icon.png',
                                      width: 18,
                                      height: 18,
                                      color: Colors.white,
                                    ),
                                    label: const Text("Edit"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        state.isOperationLoading
                                            ? null
                                            : () => _showDeleteDialog(
                                              context,
                                              visitor,
                                              state,
                                            ),
                                    icon: Image.asset(
                                      'assets/icons/delete_icon.png',
                                      width: 18,
                                      height: 18,
                                      color: Colors.white,
                                    ),
                                    label: const Text("Delete"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF43F5E),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      elevation: 2,
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
              loading: () => const AppLoadingWidget(),
              error:
                  (e, _) => AppErrorWidget(
                    message: e.toString(),
                    onRetry:
                        () =>
                            ref
                                .read(tenantAdminProvider.notifier)
                                .fetchAllVisitors(),
                  ),
            ),
          ),
          if (state.isOperationLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: AppLoadingWidget()),
            ),
        ],
      ),
    );
  }

  ImageProvider? _safeImage(dynamic imageUrl) {
    if (imageUrl == null) return null;

    String value = imageUrl.toString();
    if (value.isEmpty) return null;

    try {
      // Case 1: Normal network image
      if (value.startsWith('http')) {
        return NetworkImage(value);
      }

      // Case 2: Base64 with prefix
      if (value.contains(',')) {
        value = value.split(',').last;
      }

      // Fix missing padding
      while (value.length % 4 != 0) {
        value += '=';
      }

      return MemoryImage(base64Decode(value));
    } catch (e) {
      debugPrint("Invalid image format: $e");
      return null;
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    dynamic visitor,
    TenantAdminState state,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text(
              "Delete Visitor",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            content: Text(
              "Are you sure you want to delete ${visitor['visitorName']}?",
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      onPressed:
                          state.isOperationLoading
                              ? null
                              : () async {
                                final success = await ref
                                    .read(tenantAdminProvider.notifier)
                                    .deleteVisitor(visitor['id']);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  if (success) {
                                    SnackbarUtils.showSuccess(
                                      context,
                                      "Visitor deleted successfully",
                                    );
                                  } else {
                                    SnackbarUtils.showError(
                                      context,
                                      "Failed to delete visitor",
                                    );
                                  }
                                }
                              },
                      child:
                          state.isOperationLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "DELETE",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}
