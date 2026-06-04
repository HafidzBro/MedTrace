import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/services/supabase/dashboard_service.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentDoctorDashboardSummaryProvider);

    return DoctorMockScaffold(
      currentIndex: 3,
      appBar: const DoctorTopBar(title: 'MedTrace', leadingIcon: Icons.person),
      child: summary.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: doctorTeal),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(error.toString(),
                style: const TextStyle(color: doctorMuted),
                textAlign: TextAlign.center),
          ),
        ),
        data: (data) => _AnalyticsContent(data: data),
      ),
    );
  }
}

class _AnalyticsContent extends StatefulWidget {
  final DoctorDashboardSummary data;
  const _AnalyticsContent({required this.data});

  @override
  State<_AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<_AnalyticsContent> {
  String _period = 'Today';
  String _status = 'All Statuses';

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final patientsWithTherapy =
        data.directoryItems.where((d) => d.therapy != null).toList();

    final overallAdherence = patientsWithTherapy.isEmpty
        ? 0.0
        : patientsWithTherapy
                .map((d) => d.therapy!.adherencePercentage)
                .fold(0.0, (a, b) => a + b) /
            patientsWithTherapy.length;

    final now = DateTime.now();
    final missedToday = data.directoryItems.where((d) {
      final log = d.lastLog;
      if (log == null) return false;
      return log.isMissed &&
          log.scheduledDate.year == now.year &&
          log.scheduledDate.month == now.month &&
          log.scheduledDate.day == now.day;
    }).length;

    final actionRequired = data.alerts
        .where((a) =>
            !a.actionTaken &&
            (a.severity == 'high' || a.severity == 'critical'))
        .length;

    final atRisk = data.directoryItems
        .where((d) => d.missedCount >= 2)
        .toList()
      ..sort((a, b) => b.missedCount.compareTo(a.missedCount));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 26, 36, 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adherence Monitoring',
            style: TextStyle(
                color: doctorText, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.totalPatients} patient${data.totalPatients == 1 ? '' : 's'} · ${data.activeTherapies} active therapies',
            style: const TextStyle(color: doctorMuted, fontSize: 15),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _DropdownPill(label: _period, options: const ['Today', 'This Week', 'This Month'], onSelect: (v) => setState(() => _period = v))),
              const SizedBox(width: 12),
              Expanded(child: _DropdownPill(label: _status, options: const ['All Statuses', 'Active', 'Completed'], onSelect: (v) => setState(() => _status = v))),
            ],
          ),
          const SizedBox(height: 28),
          _OverallAdherenceCard(adherence: overallAdherence),
          const SizedBox(height: 18),
          _MissedDosesCard(count: missedToday),
          const SizedBox(height: 18),
          _ActionRequiredCard(count: actionRequired),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'At-Risk Patients (2+ Missed)',
                  style: TextStyle(
                      color: doctorText,
                      fontSize: 21,
                      fontWeight: FontWeight.w800),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.patientManagement),
                child: const Text('View All',
                    style: TextStyle(
                        color: doctorTeal, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (atRisk.isEmpty)
            _EmptyAtRisk()
          else
            ...atRisk.take(5).map((item) {
              final name = item.profile.fullName?.trim().isNotEmpty == true
                  ? item.profile.fullName!
                  : (item.profile.email ?? 'Patient');
              final patientId = item.patient.patientId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AtRiskTile(
                  patientId: patientId,
                  patientName: name,
                  missedCount: item.missedCount,
                  high: item.missedCount >= 3,
                  adherence: item.therapy?.adherencePercentage,
                ),
              );
            }),
          const SizedBox(height: 16),
          _SummaryStatsCard(
            totalPatients: data.totalPatients,
            activeTherapies: data.activeTherapies,
            unresolved: data.alerts.where((a) => !a.actionTaken).length,
          ),
        ],
      ),
    );
  }
}

class _DropdownPill extends StatelessWidget {
  final String label;
  final List<String> options;
  final ValueChanged<String> onSelect;

  const _DropdownPill({
    required this.label,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFB7C3C3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: doctorText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis)),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6B7275)),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: options
            .map((o) => ListTile(
                  title: Text(o),
                  selected: o == label,
                  selectedColor: doctorTeal,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(o);
                  },
                ))
            .toList(),
      ),
    );
  }
}

class _OverallAdherenceCard extends StatelessWidget {
  final double adherence;
  const _OverallAdherenceCard({required this.adherence});

  @override
  Widget build(BuildContext context) {
    final pct = adherence.clamp(0, 100).toDouble();
    final color = pct >= 85 ? doctorTeal2 : pct >= 60 ? const Color(0xFFF59E0B) : doctorDanger;

    return DoctorCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Adherence',
                    style: TextStyle(
                        color: doctorText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                SizedBox(
                  width: 104,
                  height: 104,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 12,
                        backgroundColor: doctorNeutral,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bar_chart_rounded, color: Color(0xFF6B7275)),
              const SizedBox(height: 56),
              _Legend(color: doctorTeal, text: 'Target >85%'),
              const SizedBox(height: 8),
              _Legend(
                  color: pct >= 85 ? doctorTeal2 : doctorDanger,
                  text: pct >= 85 ? 'On Target' : 'Below Target'),
            ],
          ),
        ],
      ),
    );
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: doctorMuted, fontSize: 12)),
      ],
    );
  }
}

class _MissedDosesCard extends StatelessWidget {
  final int count;
  const _MissedDosesCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                  child: Text('Missed Doses Today',
                      style: TextStyle(
                          color: doctorText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800))),
              Icon(Icons.add_box_outlined, color: Color(0xFF6B7275)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$count',
            style: const TextStyle(
                color: doctorText,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                height: 1),
          ),
          const SizedBox(height: 8),
          Text(
            count == 0 ? 'No missed doses today' : 'patient${count == 1 ? '' : 's'} missed today',
            style: TextStyle(
                color: count > 0 ? doctorDanger : const Color(0xFF2E7D32),
                fontSize: 14),
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
              offset: const Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                  child: Text('Action Required',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800))),
              Icon(Icons.priority_high_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                height: 1),
          ),
          const SizedBox(height: 12),
          Text(
            count == 0
                ? 'No unresolved high-priority alerts'
                : 'patient${count == 1 ? '' : 's'} require immediate follow-up',
            style: const TextStyle(color: Color(0xFFA9DAD8), fontSize: 15),
          ),
          if (count > 0) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.alerts),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: doctorTeal,
                    elevation: 0),
                child: const Text('View Priority Alerts',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AtRiskTile extends StatelessWidget {
  final String patientId;
  final String patientName;
  final int missedCount;
  final bool high;
  final double? adherence;

  const _AtRiskTile({
    required this.patientId,
    required this.patientName,
    required this.missedCount,
    this.high = false,
    this.adherence,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(patientName);
    return DoctorCard(
      padding: const EdgeInsets.all(16),
      borderColor: high ? const Color(0xFFFFA7A7) : doctorBorder,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: high ? doctorDangerSoft : doctorNeutral,
            child: Text(initials,
                style: TextStyle(
                    color: high ? doctorDanger : const Color(0xFF6B7275),
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                      color: doctorText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    DoctorChip(
                      label: '$missedCount Missed',
                      color: high ? doctorDangerSoft : doctorNeutral,
                      textColor:
                          high ? doctorDanger : const Color(0xFF50585C),
                    ),
                    if (adherence != null) ...[
                      const SizedBox(width: 8),
                      DoctorChip(
                        label:
                            '${adherence!.toStringAsFixed(0)}% adherence',
                        color: adherence! >= 60
                            ? const Color(0xFFE8F5E9)
                            : doctorDangerSoft,
                        textColor: adherence! >= 60
                            ? const Color(0xFF2E7D32)
                            : doctorDanger,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: doctorTeal, size: 24),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PT';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return '$first$second'.toUpperCase();
  }
}

class _EmptyAtRisk extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: doctorBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: doctorTeal, size: 36),
          SizedBox(height: 10),
          Text(
            'No at-risk patients at this time.',
            style: TextStyle(color: doctorMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryStatsCard extends StatelessWidget {
  final int totalPatients;
  final int activeTherapies;
  final int unresolved;

  const _SummaryStatsCard({
    required this.totalPatients,
    required this.activeTherapies,
    required this.unresolved,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary',
              style: TextStyle(
                  color: doctorText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _StatRow(
              label: 'Total Patients',
              value: '$totalPatients',
              checked: true),
          const SizedBox(height: 16),
          _StatRow(
              label: 'Active Therapies',
              value: '$activeTherapies',
              checked: activeTherapies > 0),
          const SizedBox(height: 16),
          _StatRow(
              label: 'Unresolved Alerts',
              value: '$unresolved',
              checked: unresolved == 0,
              danger: unresolved > 0),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool checked;
  final bool danger;

  const _StatRow({
    required this.label,
    required this.value,
    this.checked = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked && !danger
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          color: danger
              ? doctorDanger
              : checked
                  ? doctorTeal
                  : const Color(0xFFB6BFC1),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: doctorText, fontSize: 14))),
        DoctorChip(
            label: value,
            color: danger
                ? doctorDangerSoft
                : checked
                    ? doctorNeutral
                    : doctorNeutral,
            textColor: danger
                ? doctorDanger
                : checked
                    ? doctorMuted
                    : doctorMuted),
      ],
    );
  }
}
