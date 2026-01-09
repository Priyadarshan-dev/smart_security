import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/tenant_admin_controller.dart';
import 'add_visitor_screen.dart';
import 'approvals_screen.dart';

class TenantAdminDashboard extends ConsumerStatefulWidget {
  const TenantAdminDashboard({super.key});

  @override
  ConsumerState<TenantAdminDashboard> createState() =>
      _TenantAdminDashboardState();
}

class _TenantAdminDashboardState extends ConsumerState<TenantAdminDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tenantAdminProvider.notifier).fetchDashboardData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tenant Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh:
            () => ref.read(tenantAdminProvider.notifier).fetchDashboardData(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ref
                  .watch(tenantAdminProvider)
                  .todayVisitors
                  .when(
                    data:
                        (list) => _buildStatCard(
                          context,
                          "Visitors Today",
                          "${list.length}",
                          Colors.blue,
                        ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox(),
                  ),
              const SizedBox(height: 16),
              ref
                  .watch(tenantAdminProvider)
                  .pendingApprovals
                  .when(
                    data:
                        (list) => _buildStatCard(
                          context,
                          "Pending Approvals",
                          "${list.length}",
                          Colors.orange,
                        ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox(),
                  ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddVisitorScreen(),
                            ),
                          ),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Visitor"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ApprovalsScreen(),
                            ),
                          ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Approvals"),
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
