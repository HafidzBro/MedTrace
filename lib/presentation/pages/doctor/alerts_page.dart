import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/data/models/alert_model.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/services/supabase/dashboard_service.dart';

enum _AlertSeverityFilter { all, low, medium, high }

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  _AlertSeverityFilter _severityFilter = _AlertSeverityFilter.all;

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(currentDoctorDashboardSummaryProvider);
    final summary = summaryState.valueOrNull;
    final allAlerts = _alertViews(summary);
    final alerts = _filterAlerts(allAlerts);

    return DoctorMockScaffold(
      currentIndex: -1,
      appBar: DoctorTopBar(
        title: 'Alert Center',
        showBack: true,
        onLeadingTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.doctorDashboard);
          }
        },
        actions: const [SizedBox(width: 12)],
      ),
      child: RefreshIndicator(
        color: doctorTeal,
        onRefresh: () async {
          ref.invalidate(currentDoctorDashboardSummaryProvider);
          await ref.read(currentDoctorDashboardSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 104),
          children: [
            const Text(
              'Alert Center',
              style: TextStyle(
                color: doctorText,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Review high-risk patients and database alerts.',
              style: TextStyle(color: doctorMuted, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _SeverityFilterButton(
                value: _severityFilter,
                onChanged: (value) => setState(() => _severityFilter = value),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _AlertMetric(
                  value: summaryState.isLoading ? '...' : '${alerts.length}',
                  label: 'Open Alerts',
                ),
                const SizedBox(width: 12),
                _AlertMetric(
                  value: summaryState.isLoading
                      ? '...'
                      : '${alerts.where((item) => item.highPriority).length}',
                  label: 'High Risk',
                  danger: true,
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (summaryState.hasError && summary == null)
              _StateCard(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load alerts',
                message: summaryState.error.toString(),
              )
            else if (summaryState.isLoading && summary == null)
              const _StateCard(
                icon: Icons.sync_rounded,
                title: 'Loading alerts',
                message: 'Checking alerts from your assigned patients.',
              )
            else if (alerts.isEmpty)
              _StateCard(
                icon: Icons.verified_outlined,
                title: _severityFilter == _AlertSeverityFilter.all
                    ? 'No active alerts'
                    : 'No ${_severityFilterLabel(_severityFilter).toLowerCase()} alerts',
                message:
                    'High-risk patients and database alerts will appear here.',
              )
            else ...[
              _PriorityBanner(alerts.first),
              const SizedBox(height: 24),
              ...alerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AlertCard(
                    alert: alert,
                    onView: () => context.go(
                      AppRoutes.patientDetail,
                      extra: {
                        'patientId': alert.patientId,
                        'patientName': alert.patientName,
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_AlertView> _filterAlerts(List<_AlertView> alerts) {
    return switch (_severityFilter) {
      _AlertSeverityFilter.low =>
        alerts.where((alert) => alert.normalizedSeverity == 'low').toList(),
      _AlertSeverityFilter.medium =>
        alerts.where((alert) => alert.normalizedSeverity == 'medium').toList(),
      _AlertSeverityFilter.high =>
        alerts.where((alert) => alert.normalizedSeverity == 'high').toList(),
      _AlertSeverityFilter.all => alerts,
    };
  }
}

class _SeverityFilterButton extends StatelessWidget {
  final _AlertSeverityFilter value;
  final ValueChanged<_AlertSeverityFilter> onChanged;

  const _SeverityFilterButton({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AlertSeverityFilter>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => _AlertSeverityFilter.values
          .map(
            (item) => PopupMenuItem(
              value: item,
              child: Text(_severityFilterLabel(item)),
            ),
          )
          .toList(),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: doctorTeal2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              _severityFilterLabel(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertMetric extends StatelessWidget {
  final String value;
  final String label;
  final bool danger;

  const _AlertMetric({
    required this.value,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: danger ? doctorDangerSoft : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: danger ? const Color(0xFFFFA7A7) : doctorBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: danger ? doctorDanger : doctorTeal,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: danger ? doctorDanger : doctorMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBanner extends StatelessWidget {
  final _AlertView alert;

  const _PriorityBanner(this.alert);

  @override
  Widget build(BuildContext context) {
    if (!alert.highPriority) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: doctorDangerSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9D9D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DoctorChip(
                label: alert.priorityLabel.toUpperCase(),
                color: doctorDanger,
                textColor: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                alert.timeLabel,
                style: const TextStyle(color: doctorDanger, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.warning_rounded, color: doctorDanger),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'High-Risk Patient Alert',
                  style: TextStyle(
                    color: doctorDanger,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.body,
            style: const TextStyle(
              color: doctorDanger,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _AlertView alert;
  final VoidCallback onView;

  const _AlertCard({
    required this.alert,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor =
        alert.highPriority ? doctorDangerSoft : const Color(0xFFF1F4F4);
    final priorityText = alert.highPriority ? doctorDanger : doctorMuted;

    return DoctorCard(
      padding: const EdgeInsets.all(22),
      borderColor: alert.highPriority ? const Color(0xFFFFA7A7) : doctorBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DoctorChip(
                label: alert.priorityLabel,
                color: priorityColor,
                textColor: priorityText,
              ),
              const Spacer(),
              Text(
                alert.timeLabel,
                style: const TextStyle(color: doctorMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            alert.title,
            style: const TextStyle(
              color: doctorText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: doctorTeal,
                ),
                Text(
                  alert.patientName,
                  style: const TextStyle(
                    color: doctorTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '- ${_shortId(alert.patientId)}',
                  style: const TextStyle(color: doctorMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            alert.body,
            style: const TextStyle(
              color: Color(0xFF50585C),
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: doctorBorder),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: const Text('View Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: doctorTeal2,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, color: doctorTeal, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: doctorText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: doctorMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

List<_AlertView> _alertViews(DoctorDashboardSummary? summary) {
  if (summary == null) return const [];

  final items = <_AlertView>[];
  final highRiskPatientsWithAlert = <String>{};

  for (final alert in summary.alerts) {
    if (alert.severity == 'high' || alert.severity == 'critical') {
      highRiskPatientsWithAlert.add(alert.patientId);
    }
    items.add(_AlertView.fromDatabase(alert));
  }

  for (final item in summary.directoryItems) {
    if (!_isHighRisk(item)) continue;
    if (highRiskPatientsWithAlert.contains(item.patient.patientId)) continue;
    items.add(_AlertView.fromHighRiskPatient(item));
  }

  items.sort((a, b) {
    final severity = b.severityRank.compareTo(a.severityRank);
    if (severity != 0) return severity;
    return b.createdAt.compareTo(a.createdAt);
  });

  return items;
}

bool _isHighRisk(DoctorPatientDirectoryItem item) {
  final therapy = item.therapy;
  return item.missedCount > 0 ||
      (therapy?.isDefaulted ?? false) ||
      ((therapy?.isOngoing ?? false) &&
          (therapy?.adherencePercentage ?? 100) < 80);
}

String _patientName(DoctorPatientDirectoryItem item) {
  final fullName = item.profile.fullName.trim();
  if (fullName.isNotEmpty) return fullName;
  final email = item.profile.email.trim();
  if (email.isNotEmpty) return email;
  return 'Patient';
}

String _formatAlertType(String type) {
  return switch (type) {
    'missed_medication' => 'Missed Medication Alert',
    'high_risk' => 'High-Risk Default Warning',
    'treatment_completion' => 'Treatment Completion',
    _ => 'Patient Alert',
  };
}

String _shortId(String value) {
  final compact = value.replaceAll('-', '').toUpperCase();
  if (compact.length <= 8) return compact;
  return 'TBM-${compact.substring(compact.length - 6)}';
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} hours ago';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}

class _AlertView {
  final String patientId;
  final String patientName;
  final String title;
  final String body;
  final String severity;
  final DateTime createdAt;

  const _AlertView({
    required this.patientId,
    required this.patientName,
    required this.title,
    required this.body,
    required this.severity,
    required this.createdAt,
  });

  factory _AlertView.fromDatabase(AlertModel alert) {
    return _AlertView(
      patientId: alert.patientId,
      patientName: _textOrFallback(alert.patientName, 'Patient'),
      title: _textOrFallback(alert.title, _formatAlertType(alert.type)),
      body: _textOrFallback(
        alert.description,
        'A patient alert was recorded in the clinical alert table.',
      ),
      severity: alert.severity,
      createdAt: alert.createdAt,
    );
  }

  factory _AlertView.fromHighRiskPatient(DoctorPatientDirectoryItem item) {
    final therapy = item.therapy;
    final adherence = therapy?.adherencePercentage;
    final missed = item.missedCount;
    final reason = missed > 0
        ? '$missed missed medication log${missed == 1 ? '' : 's'}'
        : (therapy?.isDefaulted ?? false)
            ? 'therapy status indicates default risk'
            : 'adherence is below 80%';

    return _AlertView(
      patientId: item.patient.patientId,
      patientName: _patientName(item),
      title: 'High-Risk Default Warning',
      body: adherence == null
          ? 'Patient is flagged high risk because $reason.'
          : 'Patient is flagged high risk because $reason. Current adherence is ${adherence.toStringAsFixed(0)}%.',
      severity: _severityFromMissedCount(missed),
      createdAt: item.lastLog?.scheduledAt ?? DateTime.now(),
    );
  }

  bool get highPriority => severity == 'high' || severity == 'critical';

  String get normalizedSeverity {
    if (severity == 'critical') return 'high';
    if (severity == 'high' || severity == 'medium' || severity == 'low') {
      return severity;
    }
    return 'low';
  }

  int get severityRank {
    return switch (severity) {
      'critical' => 4,
      'high' => 3,
      'medium' => 2,
      _ => 1,
    };
  }

  String get priorityLabel {
    return switch (severity) {
      'critical' => 'Critical Priority',
      'high' => 'High Priority',
      'medium' => 'Medium Priority',
      _ => 'Low Priority',
    };
  }

  String get timeLabel => _relativeTime(createdAt);
}

String _textOrFallback(String? value, String fallback) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value.trim();
}

String _severityFromMissedCount(int missedCount) {
  if (missedCount > 3) return 'high';
  if (missedCount >= 2) return 'medium';
  if (missedCount == 1) return 'low';
  return 'low';
}

String _severityFilterLabel(_AlertSeverityFilter filter) {
  return switch (filter) {
    _AlertSeverityFilter.all => 'Filter',
    _AlertSeverityFilter.low => 'Low',
    _AlertSeverityFilter.medium => 'Medium',
    _AlertSeverityFilter.high => 'High',
  };
}
