import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ceedeeyes/core/theme/app_theme.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/security_controller.dart';
import 'visitor_entry_screen.dart';
import 'vehicle_entry_screen.dart';
import 'visitor_history_screen.dart';

class SecurityDashboard extends ConsumerStatefulWidget {
  const SecurityDashboard({super.key});

  @override
  ConsumerState<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends ConsumerState<SecurityDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      print("SecurityDashboard: Initializing data...");
      ref.read(securityProvider.notifier).fetchTodayVisitors();
      ref
          .read(securityProvider.notifier)
          .fetchTenants(); // Proper place to init
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);

    return Scaffold(
      backgroundColor: AppTheme.securityBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.securityAppBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Security Dashboard",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: MenuAnchor(
              builder:
                  (context, controller, child) => IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              menuChildren: [
                MenuItemButton(
                  onPressed: () => _showLogoutDialog(context, ref),
                  leadingIcon: const Icon(Icons.logout, color: Colors.red),
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh:
              () => ref.read(securityProvider.notifier).refreshDashboard(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    // Summary Card
                    state.todayVisitors.when(
                      data:
                          (list) => _buildGridCard(
                            context,
                            title: "Visitors\nChecked-In",
                            value:
                                "${list.where((v) => v['status'] == 'CHECKED_IN').length}",
                            assetPath: "assets/icons/visitor_checked_icon.png",
                            color: Colors.orange,
                            hideArrow: true,
                            onTap: () {},
                          ),
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (e, _) => Center(
                            child: Text(
                              "Error",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                    ),

                    // Action Cards
                    _buildGridCard(
                      context,
                      title: "Visitor\nEntry",
                      assetPath: "assets/icons/add_visitor_icon.png",
                      color: Colors.blue,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VisitorEntryScreen(),
                            ),
                          ),
                    ),
                    _buildGridCard(
                      context,
                      title: "Visitors\nList",
                      assetPath: "assets/icons/history_icon.png",
                      color: Colors.purple,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VisitorHistoryScreen(),
                            ),
                          ),
                    ),
                    _buildGridCard(
                      context,
                      title: "Vehicle\nEntry / Exit",
                      assetPath: "assets/icons/car_icon.png",
                      color: Colors.green,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VehicleEntryScreen(),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String title,
    required String assetPath,
    required Color color,
    required VoidCallback onTap,
    String? value,
    bool hideArrow = false,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: hideArrow ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Use Stack or Row for top section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    assetPath,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    color: color,
                  ),
                  if (value != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Reported",
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                ],
              ),
              const Spacer(),
              // Title and Arrow Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (!hideArrow)
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ],
          ),
        ),
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
