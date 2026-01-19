import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/security_controller.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';

class VisitorHistoryScreen extends ConsumerStatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  ConsumerState<VisitorHistoryScreen> createState() =>
      _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends ConsumerState<VisitorHistoryScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(securityProvider.notifier).fetchTodayVisitors();
      ref
          .read(securityProvider.notifier)
          .fetchVisitorReports(_startDate, _endDate);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (isStart && picked.isAfter(_endDate)) {
        if (context.mounted) {
          SnackbarUtils.showError(context, "From date cannot be after To date");
        }
        return;
      }
      if (!isStart && picked.isBefore(_startDate)) {
        if (context.mounted) {
          SnackbarUtils.showError(
            context,
            "To date cannot be before From date",
          );
        }
        return;
      }
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      ref
          .read(securityProvider.notifier)
          .fetchVisitorReports(_startDate, _endDate);
    }
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
            tabs: [Tab(text: "Checked-In"), Tab(text: "History")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCheckedInTab(state.todayVisitors),
            _buildHistoryTab(state.visitorReports),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FROM",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(_startDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "TO",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(_endDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedInTab(AsyncValue<List<dynamic>> visitors) {
    return visitors.when(
      data: (list) {
        final checkedIn =
            list.where((v) => v['status'] == 'CHECKED_IN').toList();
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
                backgroundImage:
                    item['imageUrl'] != null
                        ? MemoryImage(base64Decode(item['imageUrl']))
                        : null,
                child:
                    item['imageUrl'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(item['visitorName']),
              subtitle: Text(item['mobileNumber']),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final success = await ref
                      .read(securityProvider.notifier)
                      .checkOutVisitor(item['id']);
                  if (context.mounted) {
                    if (success) {
                      SnackbarUtils.showSuccess(
                        context,
                        "Checked Out Successfully",
                      );
                    } else {
                      SnackbarUtils.showError(context, "Failed to Check Out");
                    }
                  }
                },
                child: const Text("Check-Out"),
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
    return Column(
      children: [
        _buildDateFilter(),
        Expanded(
          child: visitors.when(
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text("No visitor history found"));
              }

              // Sort by check-in time descending (latest first)
              final sortedList = List.from(list);
              sortedList.sort((a, b) {
                DateTime parseDate(dynamic d) {
                  if (d == null) return DateTime(2000);
                  try {
                    return DateTime.parse(d.toString());
                  } catch (_) {
                    return DateTime(2000);
                  }
                }

                final aTime = parseDate(a['checkInTime']);
                final bTime = parseDate(b['checkInTime']);
                return bTime.compareTo(aTime);
              });

              return RefreshIndicator(
                onRefresh:
                    () => ref
                        .read(securityProvider.notifier)
                        .fetchVisitorReports(_startDate, _endDate),
                child: ListView.builder(
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final item = sortedList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            item['imageUrl'] != null
                                ? MemoryImage(base64Decode(item['imageUrl']))
                                : null,
                        child:
                            item['imageUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(item['visitorName'] ?? 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item['mobileNumber'] ?? 'N/A'} • ${item['status'] ?? 'N/A'}",
                          ),
                        ],
                      ),
                      trailing: Text(
                        item['visitType'] ?? item['purpose'] ?? "",
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
          ),
        ),
      ],
    );
  }
}
