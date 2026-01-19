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
              () =>
                  ref
                      .read(tenantAdminProvider.notifier)
                      .fetchPendingApprovals(),
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
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 5,
                            child: Container(color: Colors.orange.shade300),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.orange.shade50,
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.orange.shade700,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['visitorName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_android_rounded,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item['mobileNumber'],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          (item['visitType'] ?? "GUEST")
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.blueGrey.shade700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    _buildCircleAction(
                                      icon: Icons.check_rounded,
                                      color: Colors.green.shade600,
                                      isLoading: state.isOperationLoading,
                                      onTap: () async {
                                        final success = await ref
                                            .read(tenantAdminProvider.notifier)
                                            .approveOrReject(
                                              item['id'],
                                              "APPROVED",
                                              "",
                                            );
                                        if (context.mounted && success) {
                                          SnackbarUtils.showSuccess(
                                            context,
                                            "Visitor approved",
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCircleAction(
                                      icon: Icons.close_rounded,
                                      color: Colors.red.shade600,
                                      isLoading: state.isOperationLoading,
                                      onTap:
                                          () => _showRejectDialog(
                                            context,
                                            item['id'],
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildCircleAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, int visitorId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Rejection Reason"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
