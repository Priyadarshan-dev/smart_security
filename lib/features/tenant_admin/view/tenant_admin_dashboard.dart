import 'dart:convert';
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
          backgroundColor: const Color(0xFFF5F9FF),
          appBar: AppBar(
            title: Text(titles[_currentIndex]),
            centerTitle: true,
            backgroundColor: const Color(0xFF60A5FA),
            foregroundColor: Colors.white,
            elevation: 2,
            actions: [
              if (_currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutDialog(context, ref),
                ),
            ],
          ),
          body: pages[_currentIndex],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE0ECFF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SizedBox(
                  height: 90,
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    selectedItemColor: const Color(0xFF60A5FA),
                    unselectedItemColor: Colors.grey,
                    type: BottomNavigationBarType.fixed,
                    items: [
                      BottomNavigationBarItem(
                        icon: Image.asset(
                          'assets/icons/home_icon.png',
                          height: 24,
                          width: 24,
                          color:
                              _currentIndex == 0
                                  ? const Color(0xFF60A5FA)
                                  : Colors.grey,
                        ),
                        label: "Home",
                      ),
                      BottomNavigationBarItem(
                        icon: Image.asset(
                          'assets/icons/approvals_icon.png',
                          height: 24,
                          width: 24,
                          color:
                              _currentIndex == 1
                                  ? const Color(0xFF60A5FA)
                                  : Colors.grey,
                        ),
                        label: "Approvals",
                      ),
                      BottomNavigationBarItem(
                        icon: Image.asset(
                          'assets/icons/schedule_visitors_icon.png',
                          height: 24,
                          width: 24,
                          color:
                              _currentIndex == 2
                                  ? const Color(0xFF60A5FA)
                                  : Colors.grey,
                        ),
                        label: "Visitors",
                      ),
                      BottomNavigationBarItem(
                        icon: Image.asset(
                          'assets/icons/car_icon.png',
                          height: 24,
                          width: 24,
                          color:
                              _currentIndex == 3
                                  ? const Color(0xFF60A5FA)
                                  : Colors.grey,
                        ),
                        label: "Vehicles",
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                    backgroundColor: const Color(0xFF60A5FA),
                    foregroundColor: Colors.white,
                    label: const Text("Schedule"),
                    icon: const Icon(Icons.add),
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
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
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
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      child: const Text(
                        "LOGOUT",
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
                  Image.asset(
                    'assets/icons/schedule_visitors_icon.png',
                    width: 24,
                    height: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
                  Image.asset(
                    'assets/icons/approvals_icon.png',
                    width: 24,
                    height: 24,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
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
                    Icon(
                      Icons.history,
                      size: 64,
                      color: const Color(0xFFF1F5F9),
                    ),
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
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage:
                            (visitor['imageUrl'] != null &&
                                    visitor['imageUrl'].toString().isNotEmpty)
                                ? MemoryImage(base64Decode(visitor['imageUrl']))
                                : null,
                        child:
                            (visitor['imageUrl'] == null ||
                                    visitor['imageUrl'].toString().isEmpty)
                                ? Icon(
                                  Icons.person_rounded,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                )
                                : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              "Name",
                              visitor['visitorName'] ?? "N/A",
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              "Purpose",
                              visitor['visitType'] ?? "N/A",
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              "Status",
                              visitor['visitStatus'] ?? 'Scheduled',
                              color: Colors.green.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    Color color,
    Widget icon,
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
            child: SizedBox(width: 24, height: 24, child: icon),
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
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
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
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      child: const Text(
                        "LOGOUT",
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
