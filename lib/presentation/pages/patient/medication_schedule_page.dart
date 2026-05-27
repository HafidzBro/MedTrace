import 'package:flutter/material.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';

class MedicationSchedulePage extends StatelessWidget {
  const MedicationSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PatientMockScaffold(
      currentIndex: 1,
      appBar: PatientTopBar(
        title: 'My Adherence',
        leadingIcon: Icons.person,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 24, 28, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeeklySummaryCard(),
            SizedBox(height: 34),
            SectionTitle('History Log'),
            SizedBox(height: 14),
            _HistoryTile(
              icon: Icons.schedule_rounded,
              iconBg: patientNeutral,
              iconColor: Color(0xFF5F696C),
              title: 'Today, Oct 21',
              subtitle: 'Rifampin & Isoniazid',
              chip: 'Pending',
              chipBg: patientNeutral,
              chipColor: Color(0xFF4F585B),
              outlined: true,
            ),
            SizedBox(height: 12),
            _HistoryTile(
              title: 'Yesterday, Oct 20',
              subtitle: 'Taken at 08:30 AM',
              chip: 'Taken',
            ),
            SizedBox(height: 12),
            _HistoryTile(
              title: 'Thu, Oct 19',
              subtitle: 'Taken at 09:15 AM',
              chip: 'Taken',
            ),
            SizedBox(height: 12),
            _HistoryTile(
              icon: Icons.priority_high_rounded,
              iconBg: patientDangerSoft,
              iconColor: patientDanger,
              title: 'Wed, Oct 18',
              subtitle: 'Dose Missed',
              subtitleColor: patientDanger,
              chip: 'Missed',
              chipBg: patientDangerSoft,
              chipColor: patientDanger,
            ),
            SizedBox(height: 12),
            _HistoryTile(
              title: 'Tue, Oct 17',
              subtitle: 'Taken at 08:00 AM',
              chip: 'Taken',
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context) {
    return PatientCard(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Summary',
                  style: TextStyle(
                    color: patientText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Oct 16 - Oct 22',
                style: TextStyle(color: patientMuted, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekDay(label: 'Mon', status: _WeekStatus.done),
              _WeekDay(label: 'Tue', status: _WeekStatus.done),
              _WeekDay(label: 'Wed', status: _WeekStatus.missed),
              _WeekDay(label: 'Thu', status: _WeekStatus.done),
              _WeekDay(label: 'Fri', status: _WeekStatus.done),
              _WeekDay(label: 'Sat', status: _WeekStatus.current),
              _WeekDay(label: 'Sun', status: _WeekStatus.empty),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: patientBorder),
          const SizedBox(height: 16),
          const Text(
            'Adherence Rate',
            style: TextStyle(color: patientMuted, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                '80%',
                style: TextStyle(
                  color: patientTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: 128,
                height: 38,
                decoration: BoxDecoration(
                  color: patientNeutral,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: patientTeal,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _WeekStatus { done, missed, current, empty }

class _WeekDay extends StatelessWidget {
  final String label;
  final _WeekStatus status;

  const _WeekDay({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == _WeekStatus.done;
    final isMissed = status == _WeekStatus.missed;
    final isCurrent = status == _WeekStatus.current;
    final isEmpty = status == _WeekStatus.empty;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? patientTeal : patientMuted,
            fontSize: 16,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDone
                ? patientTeal2
                : isMissed
                    ? patientDangerSoft
                    : isEmpty
                        ? patientNeutral
                        : Colors.white,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: patientTeal, width: 2)
                : Border.all(color: Colors.transparent),
          ),
          child: Icon(
            isDone
                ? Icons.check_rounded
                : isMissed
                    ? Icons.close_rounded
                    : isCurrent
                        ? Icons.more_horiz_rounded
                        : Icons.remove_rounded,
            size: 18,
            color: isDone
                ? Colors.white
                : isMissed
                    ? patientDanger
                    : isCurrent
                        ? patientTeal
                        : const Color(0xFF9CA3A3),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final String chip;
  final Color chipBg;
  final Color chipColor;
  final bool outlined;

  const _HistoryTile({
    this.icon = Icons.check_rounded,
    this.iconBg = patientTeal2,
    this.iconColor = Colors.white,
    required this.title,
    required this.subtitle,
    this.subtitleColor = patientMuted,
    required this.chip,
    this.chipBg = patientTeal2,
    this.chipColor = Colors.white,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return PatientCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderColor: outlined ? const Color(0xFFB7C1C1) : Colors.white,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: patientText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chip,
              style: TextStyle(
                color: chipColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
