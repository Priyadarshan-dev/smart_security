import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/security_controller.dart';
import 'visitor_entry_screen.dart';
import 'vehicle_entry_screen.dart';

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
      ref.read(securityProvider.notifier).fetchTodayVisitors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visitors = ref.watch(securityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            visitors.when(
              data:
                  (list) => _buildSummaryCard(
                    context,
                    "Visitors Checked-In",
                    "${list.where((v) => v['status'] == 'CHECKED_IN').length}",
                    Icons.people,
                    Colors.orange,
                  ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text("Error loading stats: $e"),
            ),
            const SizedBox(height: 24),
            _buildActionCard(
              context,
              "Visitor Entry",
              Icons.person_add,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisitorEntryScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              "Vehicle Entry / Exit",
              Icons.directions_car,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleEntryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 30,
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 24),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: color),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
