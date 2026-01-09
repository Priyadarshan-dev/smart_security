import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/tenant_admin_controller.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text("Pending Approvals")),
      body: state.pendingApprovals.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                "No pending approvals found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(item['visitorName']),
                  subtitle: Text(
                    "Mobile: ${item['mobileNumber']}\nPurpose: ${item['purpose']}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed:
                            () => ref
                                .read(tenantAdminProvider.notifier)
                                .approveOrReject(item['id'], "APPROVED", ""),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _showRejectDialog(context, item['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
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
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter reason for rejection",
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
                  if (success) Navigator.pop(context);
                },
                child: const Text("REJECT"),
              ),
            ],
          ),
    );
  }
}
