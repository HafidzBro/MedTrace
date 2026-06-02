import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/services/supabase/dashboard_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum _DateFilter { all, today, yesterday, lastWeek, lastMonth }

enum _TherapyFilter { all, low, medium, high }

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  _DateFilter _dateFilter = _DateFilter.today;
  _TherapyFilter _therapyFilter = _TherapyFilter.all;

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(currentDoctorDashboardSummaryProvider);
    final summary = summaryState.valueOrNull;
    final allItems = summary?.directoryItems ?? const [];
    final alertSeverities = _alertSeverityByPatient(summary);
    final visibleItems = _filterItems(allItems, alertSeverities);
    final atRiskItems = visibleItems.where(_isAtRisk).toList()
      ..sort((a, b) => b.missedCount.compareTo(a.missedCount));
    final filteredLogs = visibleItems.expand((item) => item.logs).where((log) {
      final range = _dateRange(_dateFilter);
      if (range == null) return true;
      return _isWithin(log.scheduledAt, range);
    }).toList();
    final missedLogs = filteredLogs.where((log) => log.isMissed).toList();
    final missedYesterday = allItems
        .expand((item) => item.logs)
        .where(
            (log) => log.isMissed && _isWithin(log.scheduledAt, _yesterday()))
        .length;
    final adherence = _averageAdherence(visibleItems);

    return DoctorMockScaffold(
      currentIndex: 3,
      appBar: const DoctorTopBar(title: 'MedTrace', leadingIcon: Icons.person),
      child: RefreshIndicator(
        color: doctorTeal,
        onRefresh: () async {
          ref.invalidate(currentDoctorDashboardSummaryProvider);
          await ref.read(currentDoctorDashboardSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(36, 26, 36, 104),
          children: [
            const Text(
              'Adherence Monitoring',
              style: TextStyle(
                color: doctorText,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              summaryState.isLoading
                  ? 'Loading assigned patient data'
                  : '${visibleItems.length} assigned patients in view',
              style: const TextStyle(color: doctorMuted, fontSize: 15),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _FilterPill<_DateFilter>(
                    label: _dateFilterLabel(_dateFilter),
                    value: _dateFilter,
                    values: _DateFilter.values,
                    labelFor: _dateFilterLabel,
                    onChanged: (value) => setState(() => _dateFilter = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterPill<_TherapyFilter>(
                    label: _therapyFilterLabel(_therapyFilter),
                    value: _therapyFilter,
                    values: _TherapyFilter.values,
                    labelFor: _therapyFilterLabel,
                    onChanged: (value) =>
                        setState(() => _therapyFilter = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (summaryState.hasError && summary == null)
              _StateCard(
                title: 'Unable to load monitoring',
                message: summaryState.error.toString(),
              )
            else ...[
              _OverallAdherenceCard(adherence: adherence),
              const SizedBox(height: 18),
              _MissedDosesCard(
                count: missedLogs.length,
                yesterdayCount: missedYesterday,
                label: _dateFilterLabel(_dateFilter),
              ),
              const SizedBox(height: 18),
              _ActionRequiredCard(count: atRiskItems.length),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'At-Risk Patients',
                      style: TextStyle(
                        color: doctorText,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.alerts),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (atRiskItems.isEmpty)
                const _StateCard(
                  title: 'No at-risk patients',
                  message:
                      'Patients with missed doses or low adherence will appear here.',
                )
              else
                ...atRiskItems.take(5).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _AtRiskTile(item: item),
                      ),
                    ),
              const SizedBox(height: 8),
              _QuickFiltersCard(
                activeFilter: _therapyFilter,
                highCount: _severityCount(allItems, alertSeverities, 'high'),
                mediumCount:
                    _severityCount(allItems, alertSeverities, 'medium'),
                lowCount: _severityCount(allItems, alertSeverities, 'low'),
                onFilter: (filter) => setState(() => _therapyFilter = filter),
              ),
              const SizedBox(height: 26),
              _RegionalCard(
                missedCount: missedLogs.length,
                onViewMap: () => context.go(AppRoutes.doctorMap),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<DoctorPatientDirectoryItem> _filterItems(
    List<DoctorPatientDirectoryItem> items,
    Map<String, String> alertSeverities,
  ) {
    final byStatus = items.where((item) {
      return switch (_therapyFilter) {
        _TherapyFilter.low =>
          _monitoringSeverity(item, alertSeverities) == 'low',
        _TherapyFilter.medium =>
          _monitoringSeverity(item, alertSeverities) == 'medium',
        _TherapyFilter.high =>
          _monitoringSeverity(item, alertSeverities) == 'high',
        _TherapyFilter.all => true,
      };
    });

    final range = _dateRange(_dateFilter);
    if (range == null) return byStatus.toList();
    return byStatus.where((item) {
      if (item.logs.isEmpty) return true;
      return item.logs.any((log) => _isWithin(log.scheduledAt, range));
    }).toList();
  }
}

class _FilterPill<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  const _FilterPill({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => values
          .map((item) => PopupMenuItem<T>(
                value: item,
                child: Text(labelFor(item)),
              ))
          .toList(),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFB7C3C3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: doctorText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: doctorMuted),
          ],
        ),
      ),
    );
  }
}

class _OverallAdherenceCard extends StatelessWidget {
  final double adherence;

  const _OverallAdherenceCard({required this.adherence});

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Overall Adherence',
                  style: TextStyle(
                    color: doctorText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: doctorMuted),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _AdherenceRing(value: adherence),
              const SizedBox(width: 28),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend(color: doctorTeal, text: 'Target >85%'),
                    SizedBox(height: 12),
                    _Legend(color: doctorNeutral, text: 'Below Target'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdherenceRing extends StatelessWidget {
  final double value;

  const _AdherenceRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size.square(138),
        painter: _AdherenceRingPainter(value),
        child: SizedBox.square(
          dimension: 108,
          child: Center(
            child: Text(
              '${value.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: doctorTeal,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdherenceRingPainter extends CustomPainter {
  final double value;

  const _AdherenceRingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 18) / 2;
    final background = Paint()
      ..color = doctorNeutral
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final foreground = Paint()
      ..color = doctorTeal2
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, background);
    final sweep = 360 * (value / 100).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.141592653589793 / 180,
      sweep * 3.141592653589793 / 180,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _AdherenceRingPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: doctorMuted, fontSize: 13)),
      ],
    );
  }
}

class _MissedDosesCard extends StatelessWidget {
  final int count;
  final int yesterdayCount;
  final String label;

  const _MissedDosesCard({
    required this.count,
    required this.yesterdayCount,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Missed Doses - $label',
            style: const TextStyle(
              color: doctorText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$count',
            style: const TextStyle(
              color: doctorText,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$yesterdayCount missed yesterday',
            style: TextStyle(
              color: yesterdayCount > 0 ? doctorDanger : doctorMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRequiredCard extends StatelessWidget {
  final int count;

  const _ActionRequiredCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: doctorTeal2,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: doctorTeal.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Action Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Patients require immediate follow-up',
            style: TextStyle(color: Color(0xFFA9DAD8), fontSize: 15),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.alerts),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: doctorTeal,
                elevation: 0,
              ),
              child: const Text(
                'View Priority Cases',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtRiskTile extends StatelessWidget {
  final DoctorPatientDirectoryItem item;

  const _AtRiskTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final missed = item.missedCount;
    final high = missed >= 2 || (item.therapy?.adherencePercentage ?? 100) < 60;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(
        AppRoutes.patientDetail,
        extra: {
          'patientId': item.patient.patientId,
          'patientName': _patientName(item),
        },
      ),
      child: DoctorCard(
        padding: const EdgeInsets.all(16),
        borderColor: high ? const Color(0xFFFFA7A7) : doctorBorder,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: high ? doctorDangerSoft : doctorNeutral,
              child: Icon(
                high ? Icons.warning_amber_rounded : Icons.person_outline,
                color: high ? doctorDanger : doctorMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _patientName(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: doctorText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DoctorChip(
                    label: '$missed missed dose${missed == 1 ? '' : 's'}',
                    color: high ? doctorDangerSoft : doctorNeutral,
                    textColor: high ? doctorDanger : doctorMuted,
                  ),
                ],
              ),
            ),
            _WhatsAppButton(item: item),
          ],
        ),
      ),
    );
  }
}

class _QuickFiltersCard extends StatelessWidget {
  final _TherapyFilter activeFilter;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final ValueChanged<_TherapyFilter> onFilter;

  const _QuickFiltersCard({
    required this.activeFilter,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Filters',
            style: TextStyle(
              color: doctorText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 26),
          _FilterRow(
            label: 'Immediate Action',
            count: '$highCount',
            checked: activeFilter == _TherapyFilter.high,
            onTap: () => onFilter(_TherapyFilter.high),
          ),
          const SizedBox(height: 20),
          _FilterRow(
            label: 'Missed 2-3 Times',
            count: '$mediumCount',
            checked: activeFilter == _TherapyFilter.medium,
            onTap: () => onFilter(_TherapyFilter.medium),
          ),
          const SizedBox(height: 20),
          _FilterRow(
            label: 'Missed Once',
            count: '$lowCount',
            checked: activeFilter == _TherapyFilter.low,
            onTap: () => onFilter(_TherapyFilter.low),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final String count;
  final bool checked;
  final VoidCallback onTap;

  const _FilterRow({
    required this.label,
    required this.count,
    required this.onTap,
    this.checked = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            checked
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: checked ? doctorTeal : const Color(0xFFB6BFC1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: doctorText, fontSize: 14),
            ),
          ),
          DoctorChip(
            label: count,
            color: checked ? doctorDangerSoft : doctorNeutral,
            textColor: checked ? doctorDanger : doctorMuted,
          ),
        ],
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  final DoctorPatientDirectoryItem item;

  const _WhatsAppButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final phone = _whatsAppPhone(item.profile.phoneNumber);
    return IconButton(
      tooltip: 'Contact via WhatsApp',
      onPressed: phone == null ? null : () => _openWhatsApp(context, phone),
      icon: Icon(
        Icons.chat_outlined,
        color: phone == null ? doctorMuted : const Color(0xFF008A4B),
        size: 30,
      ),
    );
  }
}

class _RegionalCard extends StatelessWidget {
  final int missedCount;
  final VoidCallback onViewMap;

  const _RegionalCard({
    required this.missedCount,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Regional View',
            style: TextStyle(
              color: doctorText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            missedCount > 0
                ? '$missedCount missed dose records are visible in the current monitoring filter.'
                : 'No missed dose concentration is visible in the current monitoring filter.',
            style:
                const TextStyle(color: doctorMuted, fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onViewMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('View Map'),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String message;

  const _StateCard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.monitor_heart_outlined, color: doctorTeal, size: 34),
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
            style:
                const TextStyle(color: doctorMuted, fontSize: 14, height: 1.35),
          ),
        ],
      ),
    );
  }
}

bool _isAtRisk(DoctorPatientDirectoryItem item) {
  final therapy = item.therapy;
  return item.missedCount > 0 ||
      (therapy?.isDefaulted ?? false) ||
      ((therapy?.isOngoing ?? false) &&
          (therapy?.adherencePercentage ?? 100) < 80);
}

int _severityCount(
  List<DoctorPatientDirectoryItem> items,
  Map<String, String> alertSeverities,
  String severity,
) {
  return items.where((item) {
    return _monitoringSeverity(item, alertSeverities) == severity;
  }).length;
}

double _averageAdherence(List<DoctorPatientDirectoryItem> items) {
  final therapies = items
      .map((item) => item.therapy)
      .where((therapy) => therapy != null)
      .toList();
  if (therapies.isEmpty) return 0;
  final total = therapies.fold<double>(
    0,
    (sum, therapy) => sum + therapy!.adherencePercentage,
  );
  return total / therapies.length;
}

String _patientName(DoctorPatientDirectoryItem item) {
  final fullName = item.profile.fullName.trim();
  if (fullName.isNotEmpty) return fullName;
  final email = item.profile.email.trim();
  if (email.isNotEmpty) return email;
  return 'Patient';
}

String _dateFilterLabel(_DateFilter filter) {
  return switch (filter) {
    _DateFilter.all => 'All',
    _DateFilter.today => 'Today',
    _DateFilter.yesterday => 'Yesterday',
    _DateFilter.lastWeek => 'Last Week',
    _DateFilter.lastMonth => 'Last Month',
  };
}

String _therapyFilterLabel(_TherapyFilter filter) {
  return switch (filter) {
    _TherapyFilter.all => 'All Statuses',
    _TherapyFilter.low => 'Low',
    _TherapyFilter.medium => 'Medium',
    _TherapyFilter.high => 'High',
  };
}

Map<String, String> _alertSeverityByPatient(DoctorDashboardSummary? summary) {
  if (summary == null) return const {};
  final severities = <String, String>{};
  for (final alert in summary.alerts) {
    final currentRank = _severityRank(severities[alert.patientId]);
    final nextRank = _severityRank(alert.severity);
    if (nextRank > currentRank) {
      severities[alert.patientId] = alert.severity;
    }
  }
  return severities;
}

String _monitoringSeverity(
  DoctorPatientDirectoryItem item,
  Map<String, String> alertSeverities,
) {
  final fromAlert = alertSeverities[item.patient.patientId];
  if (fromAlert == 'critical') return 'high';
  if (fromAlert == 'low' || fromAlert == 'medium' || fromAlert == 'high') {
    return fromAlert ?? 'none';
  }
  final missed = item.missedCount;
  if (missed > 3) return 'high';
  if (missed >= 2) return 'medium';
  if (missed == 1) return 'low';
  if ((item.therapy?.adherencePercentage ?? 100) < 80) return 'low';
  return 'none';
}

int _severityRank(String? severity) {
  return switch (severity) {
    'high' || 'critical' => 3,
    'medium' => 2,
    'low' => 1,
    _ => 0,
  };
}

String? _whatsAppPhone(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  var phone = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (phone.startsWith('+')) phone = phone.substring(1);
  if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
  if (phone.length < 8) return null;
  return phone;
}

Future<void> _openWhatsApp(BuildContext context, String phone) async {
  final uri = Uri.parse('https://wa.me/$phone');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (launched || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Unable to open WhatsApp.')),
  );
}

({DateTime start, DateTime end})? _dateRange(_DateFilter filter) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return switch (filter) {
    _DateFilter.all => null,
    _DateFilter.today => (
        start: today,
        end: today.add(const Duration(days: 1))
      ),
    _DateFilter.yesterday => _yesterday(),
    _DateFilter.lastWeek => (
        start: today.subtract(const Duration(days: 7)),
        end: today.add(const Duration(days: 1)),
      ),
    _DateFilter.lastMonth => (
        start: DateTime(now.year, now.month - 1, now.day),
        end: today.add(const Duration(days: 1)),
      ),
  };
}

({DateTime start, DateTime end}) _yesterday() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 1));
  return (start: start, end: today);
}

bool _isWithin(DateTime value, ({DateTime start, DateTime end}) range) {
  return !value.isBefore(range.start) && value.isBefore(range.end);
}
