import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../controller/tenant_admin_controller.dart';
import '../../../core/utils/snackbar_utils.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tenantAdminProvider.notifier).fetchPendingApprovals(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantAdminProvider);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh:
              () => ref.read(tenantAdminProvider.notifier).fetchPendingApprovals(),
          child: state.pendingApprovals.when(
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No pending approvals",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.orange),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['visitorName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Mobile: ${item['mobileNumber']}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['visitType'] ?? "GUEST",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: state.isOperationLoading
                                ? null
                                : () async {
                                  final success = await ref
                                      .read(tenantAdminProvider.notifier)
                                      .approveOrReject(
                                        item['id'],
                                        "APPROVED",
                                        "",
                                      );
                                  if (context.mounted) {
                                    if (success) {
                                      SnackbarUtils.showSuccess(
                                        context,
                                        "Visitor approved successfully",
                                      );
                                    } else {
                                      SnackbarUtils.showError(
                                        context,
                                        "Failed to approve visitor",
                                      );
                                    }
                                  }
                                },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: state.isOperationLoading
                                ? null
                                : () => _showRejectDialog(context, item['id']),
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
                      () => ref
                          .read(tenantAdminProvider.notifier)
                          .fetchPendingApprovals(),
                ),
          ),
        ),
        if (state.isOperationLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: AppLoadingWidget()),
          ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context, int visitorId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Rejection Reason"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter reason for rejection",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await ref
                      .read(tenantAdminProvider.notifier)
                      .approveOrReject(visitorId, "REJECTED", controller.text);
                  if (context.mounted) {
                    if (success) {
                      SnackbarUtils.showSuccess(
                        context,
                        "Visitor rejected successfully",
                      );
                      Navigator.pop(context);
                    } else {
                      SnackbarUtils.showError(
                        context,
                        "Failed to reject visitor",
                      );
                    }
                  }
                },
                child: const Text("REJECT"),
              ),
            ],
          ),
    );
  }
}
