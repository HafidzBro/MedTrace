import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medtrace/data/models/alert_model.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const DoctorMockScaffold(
        currentIndex: 3,
        appBar: DoctorTopBar(title: 'MedTrace'),
        child: Center(child: Text('Not authenticated')),
      );
    }

    final alertsState = ref.watch(doctorAlertsProvider(user.id));
    final filteredAlerts = _applyFilter(alertsState.alerts);
    final hasHighPriority = alertsState.alerts
        .any((a) => a.severity == 'critical' || a.severity == 'high');

    return DoctorMockScaffold(
      currentIndex: 3,
      appBar: const DoctorTopBar(title: 'MedTrace'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alert Center',
                        style: TextStyle(
                            color: doctorText,
                            fontSize: 26,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alertsState.alerts.length} total alert${alertsState.alerts.length == 1 ? '' : 's'}',
                        style:
                            const TextStyle(color: doctorMuted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                if (alertsState.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: doctorTeal),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterChips(
              selected: _filter,
              onSelect: (v) => setState(() => _filter = v),
              alerts: alertsState.alerts,
            ),
            const SizedBox(height: 24),
            if (hasHighPriority && _filter == 'all')
              _HighPriorityBanner(
                count: alertsState.alerts
                    .where((a) =>
                        a.severity == 'critical' || a.severity == 'high')
                    .length,
              ),
            if (hasHighPriority && _filter == 'all') const SizedBox(height: 20),
            if (alertsState.error != null)
              _ErrorTile(message: alertsState.error!)
            else if (filteredAlerts.isEmpty && !alertsState.isLoading)
              _EmptyTile(filter: _filter)
            else
              ...filteredAlerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AlertCard(
                    alert: alert,
                    onView: () => context.go(
                      AppRoutes.patientDetail,
                      extra: {'patientId': alert.patientId},
                    ),
                    onResolve: alert.actionTaken
                        ? null
                        : () => ref
                            .read(doctorAlertsProvider(user.id).notifier)
                            .markAsResolved(alert.alertId),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<AlertModel> _applyFilter(List<AlertModel> alerts) {
    switch (_filter) {
      case 'high':
        return alerts
            .where(
                (a) => a.severity == 'high' || a.severity == 'critical')
            .toList();
      case 'medium':
        return alerts.where((a) => a.severity == 'medium').toList();
      case 'resolved':
        return alerts.where((a) => a.actionTaken).toList();
      default:
        return alerts;
    }
  }
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final List<AlertModel> alerts;

  const _FilterChips({
    required this.selected,
    required this.onSelect,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('all', 'All (${alerts.length})'),
      (
        'high',
        'High (${alerts.where((a) => a.severity == 'high' || a.severity == 'critical').length})'
      ),
      (
        'medium',
        'Medium (${alerts.where((a) => a.severity == 'medium').length})'
      ),
      ('resolved', 'Resolved (${alerts.where((a) => a.actionTaken).length})'),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return GestureDetector(
          onTap: () => onSelect(opt.$1),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? doctorTeal2 : Colors.white,
              border: Border.all(
                  color: isSelected ? doctorTeal2 : const Color(0xFFB7C3C3)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                color: isSelected ? Colors.white : doctorMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HighPriorityBanner extends StatelessWidget {
  final int count;
  const _HighPriorityBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: doctorDangerSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9D9D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: doctorDanger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count high-priority alert${count == 1 ? '' : 's'} require immediate attention.',
              style: const TextStyle(
                  color: doctorDanger, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onView;
  final VoidCallback? onResolve;

  const _AlertCard({
    required this.alert,
    required this.onView,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical =
        alert.severity == 'critical' || alert.severity == 'high';
    final isResolved = alert.actionTaken;

    final priorityLabel = alert.severity == 'critical'
        ? 'Critical'
        : alert.severity == 'high'
            ? 'High Priority'
            : alert.severity == 'medium'
                ? 'Medium Priority'
                : 'Low Priority';

    final priorityBg = isCritical
        ? doctorDangerSoft
        : alert.severity == 'medium'
            ? const Color(0xFFFFF3E0)
            : doctorNeutral;

    final priorityFg = isCritical
        ? doctorDanger
        : alert.severity == 'medium'
            ? const Color(0xFF8C4A1F)
            : const Color(0xFF50585C);

    final patientName = alert.patientName?.isNotEmpty == true
        ? alert.patientName!
        : (alert.patientEmail?.isNotEmpty == true
            ? alert.patientEmail!
            : 'Patient');

    final displayTitle = alert.title?.isNotEmpty == true
        ? alert.title!
        : _formatType(alert.type);

    final timeStr = _formatTime(alert.createdAt);

    return DoctorCard(
      padding: const EdgeInsets.all(20),
      borderColor: isResolved
          ? doctorBorder
          : isCritical
              ? const Color(0xFFFF9D9D)
              : doctorBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DoctorChip(
                  label: priorityLabel,
                  color: priorityBg,
                  textColor: priorityFg),
              if (isResolved) ...[
                const SizedBox(width: 8),
                const DoctorChip(
                    label: 'Resolved',
                    color: Color(0xFFE8F5E9),
                    textColor: Color(0xFF2E7D32)),
              ],
              const Spacer(),
              Text(timeStr,
                  style: const TextStyle(color: doctorMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayTitle,
            style: const TextStyle(
                color: doctorText, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 15, color: doctorTeal),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    patientName,
                    style: const TextStyle(
                        color: doctorTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (alert.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              alert.description!,
              style: const TextStyle(
                  color: Color(0xFF50585C), fontSize: 14, height: 1.4),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(color: doctorBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onResolve != null)
                TextButton(
                  onPressed: onResolve,
                  style: TextButton.styleFrom(foregroundColor: doctorMuted),
                  child: const Text('Mark Resolved'),
                ),
              if (onResolve != null) const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('View Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: doctorTeal2,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatType(String value) {
    if (value.isEmpty) return 'Alert';
    return value
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

class _EmptyTile extends StatelessWidget {
  final String filter;
  const _EmptyTile({required this.filter});

  @override
  Widget build(BuildContext context) {
    final msg = filter == 'resolved'
        ? 'No resolved alerts yet.'
        : filter == 'all'
            ? 'No alerts at this time.'
            : 'No $filter priority alerts.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: doctorBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: doctorTeal, size: 40),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(color: doctorMuted, fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: doctorDangerSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9D9D)),
      ),
      child: Text(message,
          style: const TextStyle(color: doctorDanger, fontSize: 14)),
    );
  }
}
