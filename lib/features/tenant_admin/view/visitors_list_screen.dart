import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../controller/tenant_admin_controller.dart';
import 'edit_visitor_screen.dart';
import '../../../core/utils/snackbar_utils.dart';

class VisitorsListScreen extends ConsumerStatefulWidget {
  const VisitorsListScreen({super.key});

  @override
  ConsumerState<VisitorsListScreen> createState() => _VisitorsListScreenState();
}

class _VisitorsListScreenState extends ConsumerState<VisitorsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tenantAdminProvider.notifier).fetchAllVisitors(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantAdminProvider);
    final visitorsAsync = state.allVisitors;

    return Stack(
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
                        color: Colors.grey.shade300,
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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(
                        visitor['visitorName'] ?? "N/A",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "${visitor['visitType']} • ${visitor['visitDate']}",
                          ),
                          Text(
                            "Mobile: ${visitor['mobileNumber']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                            ),
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
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed:
                                state.isOperationLoading
                                    ? null
                                    : () => _showDeleteDialog(context, visitor),
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
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic visitor) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Visitor"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Text(
              "Are you sure you want to delete ${visitor['visitorName']}?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
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
                child: const Text("DELETE"),
              ),
            ],
          ),
    );
  }
}
