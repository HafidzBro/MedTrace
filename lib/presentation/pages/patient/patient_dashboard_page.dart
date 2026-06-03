import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final summary = ref.watch(currentPatientDashboardSummaryProvider);
    final firstName = _firstName(user?.fullName ?? user?.email ?? 'Patient');
    final therapy = summary.valueOrNull?.therapy;
    final progress = _therapyProgress(therapy?.treatmentDaysElapsed ?? 0);
    final recentLogs = summary.valueOrNull?.recentLogs ?? const [];

    return PatientMockScaffold(
      currentIndex: 0,
      appBar: PatientTopBar(
        title: 'Good Morning',
        leadingIcon: Icons.person,
        onLeadingTap: () => context.go(AppRoutes.patientProfile),
      ),
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: patientTeal,
          onRefresh: () => _refresh(context, ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(36, 26, 36, 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName',
                  style: const TextStyle(
                    color: patientText,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Here is your treatment plan for today.',
                  style: TextStyle(
                    color: patientMuted,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 34),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go(AppRoutes.adherenceHistory),
                  child: PatientCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_graph_rounded,
                                color: patientTeal),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Therapy Progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: patientText,
                                ),
                              ),
                            ),
                            Text(
                              therapy == null
                                  ? 'No active therapy'
                                  : 'Day ${therapy.treatmentDaysElapsed}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: patientTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: patientNeutral,
                            valueColor:
                                const AlwaysStoppedAnimation(patientTeal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _MedicineCard(
                  isLoading: summary.isLoading,
                  nextDoseLabel: _nextDoseLabel(recentLogs),
                  canLogDose: therapy != null && !summary.isLoading,
                  onLogDose: () => context.go(AppRoutes.reminders),
                ),
                const SizedBox(height: 32),
                const SectionTitle('Weekly Adherence'),
                const SizedBox(height: 12),
                PatientCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _weekDots(recentLogs),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 172,
                  child: PatientCard(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.go(AppRoutes.chatbot),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: patientMintSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.smart_toy_outlined,
                              color: patientTeal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Talk to\nMedTrace Bot',
                            style: TextStyle(
                              color: patientText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    ref.invalidate(currentPatientDashboardSummaryProvider);
    ref.invalidate(currentPatientIntakePlanProvider);
    ref.invalidate(currentPatientAdherenceHistoryProvider);
    await ref.read(currentPatientDashboardSummaryProvider.future);
  }

  static String _firstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Patient';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static double _therapyProgress(int days) {
    if (days <= 0) return 0;
    return (days / 180).clamp(0.0, 1.0);
  }

  static String _nextDoseLabel(List<dynamic> logs) {
    final todayLogs = _logsForDate(logs, DateTime.now());
    if (todayLogs.any((log) => log.isTaken)) return 'Logged today';
    if (todayLogs.any((log) => log.isMissed)) return 'Missed today';

    final pending = logs.where((log) => log.isPending).toList();
    if (pending.isEmpty) return 'Today, 08:00 AM';

    final scheduled = pending.first.scheduledAt as DateTime;
    final hour = scheduled.hour.toString().padLeft(2, '0');
    final minute = scheduled.minute.toString().padLeft(2, '0');
    return 'Today, $hour:$minute';
  }

  static List<Widget> _weekDots(List<dynamic> logs) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();

    return List.generate(days.length, (index) {
      final date = now.subtract(Duration(days: now.weekday - index - 1));
      final dayLogs = _logsForDate(logs, date);

      final status = dayLogs.any((log) => log.isTaken)
          ? _DayStatus.done
          : dayLogs.any((log) => log.isMissed)
              ? _DayStatus.missed
              : index == now.weekday - 1
                  ? _DayStatus.current
                  : _DayStatus.empty;

      return _DayDot(day: days[index], status: status);
    });
  }

  static List<dynamic> _logsForDate(List<dynamic> logs, DateTime date) {
    return logs.where((log) {
      final scheduled = log.scheduledDate as DateTime;
      return scheduled.year == date.year &&
          scheduled.month == date.month &&
          scheduled.day == date.day;
    }).toList();
  }
}

class _MedicineCard extends StatelessWidget {
  final VoidCallback onLogDose;
  final bool isLoading;
  final bool canLogDose;
  final String nextDoseLabel;

  const _MedicineCard({
    required this.onLogDose,
    required this.isLoading,
    required this.canLogDose,
    required this.nextDoseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: patientTeal2,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: patientTeal.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PatientChip(
                label: isLoading ? 'Loading schedule...' : nextDoseLabel,
                color: Colors.white,
                textColor: patientTeal,
              ),
              const Spacer(),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_rounded, color: patientTeal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Medicine',
            style: TextStyle(
              color: Color(0xFFA9DAD8),
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Take with food. Do not skip.',
            style: TextStyle(color: Color(0xFFA9DAD8), fontSize: 14),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: canLogDose ? onLogDose : null,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
              label: const Text('Log Dose'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF004D50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DayStatus { empty, done, missed, current }

class _DayDot extends StatelessWidget {
  final String day;
  final _DayStatus status;

  const _DayDot({
    required this.day,
    this.status = _DayStatus.empty,
  });

  @override
  Widget build(BuildContext context) {
    final filled = status == _DayStatus.done;
    final missed = status == _DayStatus.missed;
    final current = status == _DayStatus.current;
    return Column(
      children: [
        Text(day, style: const TextStyle(color: patientMuted, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filled
                ? patientMint
                : missed
                    ? const Color(0xFFFFE5E5)
                    : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: current
                  ? patientTeal
                  : missed
                      ? const Color(0xFFE57373)
                      : patientBorder,
              width: current || missed ? 2 : 1,
            ),
          ),
          child: Icon(
            filled
                ? Icons.check_rounded
                : missed
                    ? Icons.close_rounded
                    : current
                        ? Icons.circle
                        : null,
            size: filled || missed ? 18 : 10,
            color: missed ? const Color(0xFFD32F2F) : patientTeal,
          ),
        ),
      ],
    );
  }
}
