import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _filter = 'all'; // 'all', 'check_in', 'check_out'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      Provider.of<AttendanceProvider>(context, listen: false).fetchLogs(currentUserId: user?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final attProvider = context.watch<AttendanceProvider>();

    final filteredLogs = attProvider.logs.where((log) {
      if (_filter == 'check_in') return log.isCheckIn;
      if (_filter == 'check_out') return !log.isCheckIn;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Audit Logs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.cyan),
            onPressed: () => attProvider.fetchLogs(currentUserId: user?.id),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => attProvider.fetchLogs(currentUserId: user?.id),
        child: Column(
          children: [
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Logs',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Check-Ins',
                    selected: _filter == 'check_in',
                    onTap: () => setState(() => _filter = 'check_in'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Check-Outs',
                    selected: _filter == 'check_out',
                    onTap: () => setState(() => _filter = 'check_out'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: attProvider.isLoadingLogs
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLogs.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 50, color: AppTheme.textDark),
                              SizedBox(height: 12),
                              Text('No matching logs found', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: (log.isCheckIn ? AppTheme.emerald : AppTheme.amber).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      log.isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                                      color: log.isCheckIn ? AppTheme.emerald : AppTheme.amber,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              log.isCheckIn ? 'Verified Check-In' : 'Check-Out',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.emerald.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('✓ VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMMM yyyy, hh:mm:ss a').format(log.timestamp),
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Device: ${log.deviceInfo}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(log.confidence * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryLight : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
