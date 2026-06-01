import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class AdherenceHistoryPage extends ConsumerWidget {
  const AdherenceHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(currentPatientAdherenceHistoryProvider);

    return PatientMockScaffold(
      currentIndex: 1,
      appBar: PatientTopBar(
        title: 'My Adherence',
        leadingIcon: Icons.person,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.reminders),
            icon: const Icon(Icons.notifications_none_rounded),
            color: patientTeal,
          ),
        ],
      ),
      child: history.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: patientTeal),
        ),
        error: (error, _) => _HistoryMessage(message: error.toString()),
        data: (logs) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklySummaryCard(logs: logs),
              const SizedBox(height: 32),
              const Text(
                'History Log',
                style: TextStyle(
                  color: patientText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              if (logs.isEmpty)
                const _HistoryMessage(
                  message: 'No medication history is available yet.',
                )
              else
                ...logs.take(30).map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HistoryLogTile(log: log),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final List<MedicationLogModel> logs;

  const _WeeklySummaryCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final weekLogs = _weekLogs(logs);
    final completed = weekLogs
        .where((log) => log.isTaken || log.isMissed || log.isSkipped)
        .toList();
    final taken = completed.where((log) => log.isTaken).length;
    final rate = completed.isEmpty ? 0 : (taken / completed.length * 100);
    final weekRange = _weekRangeLabel(DateTime.now());

    return PatientCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weekly Summary',
                  style: TextStyle(
                    color: patientText,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                weekRange,
                style: const TextStyle(color: patientMuted, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekDots(logs),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: patientBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adherence Rate',
                      style: TextStyle(color: patientMuted, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: patientTeal,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 128,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    minHeight: 38,
                    backgroundColor: patientNeutral,
                    valueColor: const AlwaysStoppedAnimation(patientTeal),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<MedicationLogModel> _weekLogs(List<MedicationLogModel> logs) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return logs
        .where((log) =>
            !log.scheduledAt.isBefore(start) && log.scheduledAt.isBefore(end))
        .toList();
  }

  static List<Widget> _weekDots(List<MedicationLogModel> logs) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    return List.generate(days.length, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayLogs = logs.where((log) => _sameDay(log.scheduledAt, date));
      final status = dayLogs.any((log) => log.isTaken)
          ? _DotStatus.taken
          : dayLogs.any((log) => log.isMissed)
              ? _DotStatus.missed
              : _sameDay(date, today)
                  ? _DotStatus.current
                  : _DotStatus.empty;

      return _SummaryDot(label: days[index], status: status);
    });
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _weekRangeLabel(DateTime date) {
    final start = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${_month(start)} ${start.day} - ${_month(end)} ${end.day}';
  }

  static String _month(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[date.month - 1];
  }
}

enum _DotStatus { empty, taken, missed, current }

class _SummaryDot extends StatelessWidget {
  final String label;
  final _DotStatus status;

  const _SummaryDot({
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final taken = status == _DotStatus.taken;
    final missed = status == _DotStatus.missed;
    final current = status == _DotStatus.current;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: label == 'Sat' ? patientText : patientMuted,
            fontWeight: label == 'Sat' ? FontWeight.w700 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: taken
                ? patientTeal
                : missed
                    ? const Color(0xFFFFD8D8)
                    : current
                        ? Colors.white
                        : patientNeutral,
            shape: BoxShape.circle,
            border: Border.all(
              color: current ? patientTeal : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            taken
                ? Icons.check_rounded
                : missed
                    ? Icons.close_rounded
                    : current
                        ? Icons.access_time
                        : Icons.remove_rounded,
            color: taken
                ? Colors.white
                : missed
                    ? const Color(0xFFD71920)
                    : current
                        ? patientTeal
                        : patientMuted,
            size: 17,
          ),
        ),
      ],
    );
  }
}

class _HistoryLogTile extends StatelessWidget {
  final MedicationLogModel log;

  const _HistoryLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final taken = log.isTaken;
    final missed = log.isMissed;
    final pending = log.isPending;
    final color = taken
        ? patientTeal
        : missed
            ? const Color(0xFFFFD8D8)
            : const Color(0xFFE2E6E6);
    final iconColor = taken
        ? Colors.white
        : missed
            ? const Color(0xFFD71920)
            : const Color(0xFF5F686B);

    return PatientCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderColor: pending ? patientBorder : Colors.transparent,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(_statusIcon(log), color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel(log.scheduledAt),
                  style: const TextStyle(
                    color: patientText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(log),
                  style: TextStyle(
                    color: missed ? const Color(0xFFD71920) : patientMuted,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          PatientChip(
            label: _statusLabel(log),
            color: taken
                ? patientTeal
                : missed
                    ? const Color(0xFFFFE5E5)
                    : patientNeutral,
            textColor: taken
                ? Colors.white
                : missed
                    ? const Color(0xFFD71920)
                    : const Color(0xFF5F686B),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(MedicationLogModel log) {
    if (log.isTaken) return Icons.check_rounded;
    if (log.isMissed) return Icons.priority_high_rounded;
    return Icons.access_time_rounded;
  }

  String _statusLabel(MedicationLogModel log) {
    if (log.isTaken) return 'Taken';
    if (log.isMissed) return 'Missed';
    return 'Pending';
  }

  String _subtitle(MedicationLogModel log) {
    if (log.isTaken && log.takenAt != null) {
      return 'Taken at ${_time(log.takenAt!)}';
    }
    if (log.isMissed) return 'Dose Missed';
    return 'Scheduled at ${_time(log.scheduledAt)}';
  }

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final prefix = _sameDay(date, today)
        ? 'Today'
        : _sameDay(date, yesterday)
            ? 'Yesterday'
            : _weekday(date);
    return '$prefix, ${_month(date)} ${date.day}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekday(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }

  String _month(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[date.month - 1];
  }

  String _time(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _HistoryMessage extends StatelessWidget {
  final String message;

  const _HistoryMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return PatientCard(
      padding: const EdgeInsets.all(20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: patientMuted, height: 1.4),
      ),
    );
  }
}
