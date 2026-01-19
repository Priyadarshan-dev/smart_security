import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/tenant_admin_controller.dart';
import 'add_visitor_screen.dart';
import 'approvals_screen.dart';
import 'visitors_list_screen.dart';
import 'tenant_vehicles_screen.dart';

class TenantAdminDashboard extends ConsumerStatefulWidget {
  const TenantAdminDashboard({super.key});

  @override
  ConsumerState<TenantAdminDashboard> createState() =>
      _TenantAdminDashboardState();
}

class _TenantAdminDashboardState extends ConsumerState<TenantAdminDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tenantAdminProvider.notifier).fetchDashboardData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _TenantHomeView(),
      const ApprovalsScreen(),
      const VisitorsListScreen(),
      const TenantVehiclesScreen(),
    ];

    final List<String> titles = [
      "Tenant Home",
      "Approvals",
      "Visitors",
      "Vehicles",
    ];

    final state = ref.watch(tenantAdminProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(titles[_currentIndex]),
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            elevation: 8,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fact_check_rounded),
                label: "Approvals",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_rounded),
                label: "Visitors",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_car_rounded),
                label: "Vehicles",
              ),
            ],
          ),
          floatingActionButton:
              _currentIndex == 0
                  ? FloatingActionButton.extended(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddVisitorScreen(),
                          ),
                        ),
                    label: const Text("Schedule"),
                    icon: const Icon(Icons.add),
                  )
                  : _currentIndex == 3
                  ? FloatingActionButton.extended(
                    onPressed:
                        () => TenantVehiclesScreen.showAddVehicleDialog(
                          context,
                          ref,
                        ),
                    label: const Text("Add Vehicle"),
                    icon: const Icon(Icons.directions_car_filled),
                  )
                  : null,
        ),
        if (state.isOperationLoading)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: AppLoadingWidget()),
            ),
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
                child: const Text("LOGOUT"),
              ),
            ],
          ),
    );
  }
}

class _TenantHomeView extends ConsumerWidget {
  const _TenantHomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tenantAdminProvider);

    // Unify loading/error from multiple providers
    final isLoading =
        state.todayVisitors.isLoading || state.pendingApprovals.isLoading;
    final hasError =
        state.todayVisitors.hasError || state.pendingApprovals.hasError;
    final errorMessage =
        state.todayVisitors.error?.toString() ??
        state.pendingApprovals.error?.toString() ??
        "Unknown error";

    if (isLoading) return const AppLoadingWidget();
    if (hasError) {
      return AppErrorWidget(
        message: errorMessage,
        onRetry:
            () => ref.read(tenantAdminProvider.notifier).fetchDashboardData(),
      );
    }

    return RefreshIndicator(
      onRefresh:
          () => ref.read(tenantAdminProvider.notifier).fetchDashboardData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  "Visitors",
                  "Today",
                  "${state.todayVisitors.value?.length ?? 0}",
                  Theme.of(context).colorScheme.primary,
                  Icons.people_alt_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  "Approvals",
                  "Pending",
                  "${state.pendingApprovals.value?.length ?? 0}",
                  Theme.of(context).colorScheme.secondary,
                  Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Recent Activity",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Placeholder or empty state for activity
          if (state.todayVisitors.value?.isEmpty ?? true)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      "No activity today",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.todayVisitors.value!.map((visitor) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visitor['visitorName'] ?? "N/A",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${visitor['visitType']} • ${visitor['visitStatus'] ?? 'SCHEDULED'}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
                child: const Text("LOGOUT"),
              ),
            ],
          ),
    );
  }
}
