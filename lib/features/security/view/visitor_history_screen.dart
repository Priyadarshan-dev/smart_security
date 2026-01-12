import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/security_controller.dart';

class VisitorHistoryScreen extends ConsumerStatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  ConsumerState<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends ConsumerState<VisitorHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(securityProvider.notifier).fetchTodayVisitors());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Visitors"),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Checked-In"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCheckedInTab(state.todayVisitors),
            _buildHistoryTab(state.todayVisitors),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedInTab(AsyncValue<List<dynamic>> visitors) {
    return visitors.when(
      data: (list) {
        final checkedIn = list.where((v) => v['status'] == 'CHECKED_IN').toList();
        if (checkedIn.isEmpty) {
          return const Center(child: Text("No visitors currently checked-in"));
        }
        return ListView.builder(
          itemCount: checkedIn.length,
          itemBuilder: (context, index) {
            final item = checkedIn[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: item['imageUrl'] != null
                    ? MemoryImage(base64Decode(item['imageUrl']))
                    : null,
                child: item['imageUrl'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(item['visitorName']),
              subtitle: Text(item['mobileNumber']),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final success = await ref
                      .read(securityProvider.notifier)
                      .checkOutVisitor(item['id']);
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Visitor Checked Out")),
                    );
                  }
                },
                child: const Text("OUT"),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildHistoryTab(AsyncValue<List<dynamic>> visitors) {
    return visitors.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text("No visitor history found"));
        }
        // Sort by most recent first if date is available, otherwise just show list
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: item['imageUrl'] != null
                    ? MemoryImage(base64Decode(item['imageUrl']))
                    : null,
                child: item['imageUrl'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(item['visitorName']),
              subtitle: Text("${item['mobileNumber']} • ${item['status']}"),
              trailing: Text(item['visitType'] ?? item['purpose'] ?? ""),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
