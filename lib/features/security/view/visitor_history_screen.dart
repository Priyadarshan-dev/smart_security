import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ceedeeyes/core/theme/app_theme.dart';
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
        backgroundColor: AppTheme.securityBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.securityAppBarColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            "Visitors",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Custom Pill TabBar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.securityTabBarColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3.0,
                      color: Color(0xFF5D4037),
                    ),
                    insets: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  labelColor: const Color(0xFF5D4037),
                  unselectedLabelColor: Colors.grey.shade400,
                  // overlayColor: MaterialStateProperty.all(Colors.transparent),
                  tabs: const [Tab(text: "Checked-In"), Tab(text: "History")],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildCheckedInTab(state.todayVisitors),
                    _buildHistoryTab(state.visitorReports),
                  ],
                ),
              ),
            ],
          ),
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: checkedIn.length,
          itemBuilder: (context, index) {
            final item = checkedIn[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              item['imageUrl'] != null
                                  ? MemoryImage(base64Decode(item['imageUrl']))
                                  : null,
                          child:
                              item['imageUrl'] == null
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['visitorName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "+91 ${item['mobileNumber'] ?? ''}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
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
                                SnackbarUtils.showError(
                                  context,
                                  "Failed to Check Out",
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerColor,
                            foregroundColor: Colors.white,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_outline, size: 18),
                              SizedBox(width: 4),
                              Text("Check-Out"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['visitType'] ?? item['purpose'] ?? 'Visitor',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final item = sortedList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage:
                                      item['imageUrl'] != null
                                          ? MemoryImage(
                                            base64Decode(item['imageUrl']),
                                          )
                                          : null,
                                  child:
                                      item['imageUrl'] == null
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['visitorName'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "+91 ${item['mobileNumber'] ?? ''}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        item['status'] == 'CHECKED_IN'
                                            ? Colors.green.withOpacity(0.1)
                                            : item['status'] == 'CHECKED_OUT'
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                    border: Border.all(
                                      color:
                                          item['status'] == 'CHECKED_IN'
                                              ? Colors.green.shade200
                                              : item['status'] == 'CHECKED_OUT'
                                              ? Colors.red.shade200
                                              : Colors.orange.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        item['status'] == 'CHECKED_IN'
                                            ? Icons.check_circle
                                            : item['status'] == 'CHECKED_OUT'
                                            ? Icons.logout
                                            : Icons.info,
                                        size: 18,
                                        color:
                                            item['status'] == 'CHECKED_IN'
                                                ? Colors.green.shade700
                                                : item['status'] ==
                                                    'CHECKED_OUT'
                                                ? Colors.red.shade700
                                                : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['status'] ?? 'N/A',
                                        style: TextStyle(
                                          color:
                                              item['status'] == 'CHECKED_IN'
                                                  ? Colors.green.shade700
                                                  : item['status'] ==
                                                      'CHECKED_OUT'
                                                  ? Colors.red.shade700
                                                  : Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['visitType'] ??
                                        item['purpose'] ??
                                        'Visitor',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
