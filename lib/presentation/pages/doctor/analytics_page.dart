import 'package:flutter/material.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DoctorMockScaffold(
      currentIndex: 3,
      appBar: DoctorTopBar(title: 'MedTrace', leadingIcon: Icons.person),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(36, 26, 36, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adherence Monitoring',
              style: TextStyle(
                  color: doctorText, fontSize: 30, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text('Sector 7 District Overview',
                style: TextStyle(color: doctorMuted, fontSize: 15)),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _DropdownPill(label: 'Today')),
                SizedBox(width: 12),
                Expanded(child: _DropdownPill(label: 'All Statuses')),
              ],
            ),
            SizedBox(height: 50),
            _OverallAdherenceCard(),
            SizedBox(height: 18),
            _MissedDosesCard(),
            SizedBox(height: 18),
            _ActionRequiredCard(),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'At-Risk Patients (2+ Missed)',
                    style: TextStyle(
                        color: doctorText,
                        fontSize: 21,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Text('View All',
                    style: TextStyle(
                        color: doctorTeal, fontWeight: FontWeight.w700)),
              ],
            ),
            SizedBox(height: 24),
            _AtRiskTile(
                patientId: '4920-A', badge: '3 Missed\nReminders', high: true),
            SizedBox(height: 16),
            _AtRiskTile(
                patientId: '8112-B', badge: '2 Missed\nReminders', high: true),
            SizedBox(height: 16),
            _AtRiskTile(patientId: '2201-C', badge: '2 Missed\nReminders'),
            SizedBox(height: 16),
            _QuickFiltersCard(),
            SizedBox(height: 26),
            DoctorCard(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Regional Alert',
                      style: TextStyle(
                          color: doctorText,
                          fontSize: 21,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 10),
                  Text(
                      'Higher than average missed doses reported in North District.',
                      style: TextStyle(
                          color: doctorMuted, fontSize: 15, height: 1.35)),
                  SizedBox(height: 18),
                  Text('View Heatmap ->',
                      style: TextStyle(
                          color: doctorTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownPill extends StatelessWidget {
  final String label;

  const _DropdownPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      fontSize: 15,
                      fontWeight: FontWeight.w500))),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7275)),
        ],
      ),
    );
  }
}

class _OverallAdherenceCard extends StatelessWidget {
  const _OverallAdherenceCard();

  @override
  Widget build(BuildContext context) {
    return const DoctorCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Adherence',
                    style: TextStyle(
                        color: doctorText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 18),
                _Donut(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF6B7275)),
              SizedBox(height: 56),
              _Legend(color: doctorTeal, text: 'Target >85%'),
              SizedBox(height: 8),
              _Legend(color: doctorNeutral, text: 'Below Target'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 0.82,
            strokeWidth: 12,
            backgroundColor: doctorNeutral,
            valueColor: AlwaysStoppedAnimation(doctorTeal2),
          ),
          Text('82%',
              style: TextStyle(
                  color: doctorTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
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
  const _MissedDosesCard();

  @override
  Widget build(BuildContext context) {
    return const DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          SizedBox(height: 24),
          Text('14',
              style: TextStyle(
                  color: doctorText,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          SizedBox(height: 8),
          Text('+2 since yesterday',
              style: TextStyle(color: doctorDanger, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ActionRequiredCard extends StatelessWidget {
  const _ActionRequiredCard();

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
          const Text('5',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          const SizedBox(height: 12),
          const Text('Patients require immediate follow-up',
              style: TextStyle(color: Color(0xFFA9DAD8), fontSize: 15)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: doctorTeal,
                  elevation: 0),
              child: const Text('View Priority Cases',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtRiskTile extends StatelessWidget {
  final String patientId;
  final String badge;
  final bool high;

  const _AtRiskTile({
    required this.patientId,
    required this.badge,
    this.high = false,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(16),
      borderColor: high ? const Color(0xFFFFA7A7) : doctorBorder,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: high ? doctorDangerSoft : doctorNeutral,
            child: Icon(
              high ? Icons.warning_amber_rounded : Icons.person_outline,
              color: high ? doctorDanger : const Color(0xFF6B7275),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient ID: $patientId',
                    style: const TextStyle(
                        color: doctorText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                DoctorChip(
                  label: badge,
                  color: high ? doctorDangerSoft : doctorNeutral,
                  textColor: high ? doctorDanger : const Color(0xFF50585C),
                ),
              ],
            ),
          ),
          const Icon(Icons.chat_outlined, color: Color(0xFF008A4B), size: 34),
        ],
      ),
    );
  }
}

class _QuickFiltersCard extends StatelessWidget {
  const _QuickFiltersCard();

  @override
  Widget build(BuildContext context) {
    return const DoctorCard(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Filters',
              style: TextStyle(
                  color: doctorText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 26),
          _FilterRow(
              label: 'Require Immediate Action', count: '5', checked: true),
          SizedBox(height: 20),
          _FilterRow(label: 'Missed > 3 Days', count: '12'),
          SizedBox(height: 20),
          _FilterRow(label: 'Unassigned Cases', count: '8'),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final String count;
  final bool checked;

  const _FilterRow({
    required this.label,
    required this.count,
    this.checked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
            checked
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: checked ? doctorTeal : const Color(0xFFB6BFC1)),
        const SizedBox(width: 14),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: doctorText, fontSize: 14))),
        DoctorChip(
            label: count,
            color: checked ? doctorDangerSoft : doctorNeutral,
            textColor: checked ? doctorDanger : doctorMuted),
      ],
    );
  }
}
