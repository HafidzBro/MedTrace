import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DoctorMockScaffold(
      currentIndex: 3,
      appBar: const DoctorTopBar(title: 'MedTrace'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alert Center',
              style: TextStyle(
                  color: doctorText, fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Review and resolve urgent patient notifications.',
              style: TextStyle(color: doctorMuted, fontSize: 15),
            ),
            const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded, size: 17),
              label: const Text('Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: doctorTeal2,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: doctorDangerSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF9D9D)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DoctorChip(
                          label: '! HIGH PRIORITY',
                          color: doctorDanger,
                          textColor: Colors.white),
                      SizedBox(width: 16),
                      Text('Just now',
                          style: TextStyle(color: doctorDanger, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: doctorDanger),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'High-Risk Default Warning',
                          style: TextStyle(
                              color: doctorDanger,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'System algorithm has flagged multiple missed checkpoints. Immediate outreach required to prevent treatment default.',
                    style: TextStyle(
                        color: doctorDanger, fontSize: 15, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 86),
            _AlertCard(
              priority: 'High Priority',
              time: '2 hours ago',
              title: 'Missed Medication Alert',
              patient: 'John Doe',
              meta: 'ID: #882-JD',
              body:
                  'Patient has missed 2 consecutive scheduled doses according to the VDOT system log.',
              filledButton: true,
              onView: () => context.go(AppRoutes.patientDetail,
                  extra: {'patientName': 'John Doe'}),
            ),
            const SizedBox(height: 18),
            _AlertCard(
              priority: 'Medium Priority',
              priorityColor: doctorNeutral,
              priorityText: const Color(0xFF50585C),
              time: 'Yesterday, 14:30',
              title: 'Therapy Status Change',
              patient: 'Maria Garcia',
              meta: 'Phase 2',
              body:
                  'Lab results indicate a need for regimen adjustment. Sputum conversion delayed.',
              onView: () => context.go(AppRoutes.patientDetail,
                  extra: {'patientName': 'Maria Garcia'}),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String priority;
  final Color priorityColor;
  final Color priorityText;
  final String time;
  final String title;
  final String patient;
  final String meta;
  final String body;
  final bool filledButton;
  final VoidCallback onView;

  const _AlertCard({
    required this.priority,
    this.priorityColor = doctorDangerSoft,
    this.priorityText = doctorDanger,
    required this.time,
    required this.title,
    required this.patient,
    required this.meta,
    required this.body,
    this.filledButton = false,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DoctorChip(
                  label: priority,
                  color: priorityColor,
                  textColor: priorityText),
              const Spacer(),
              Text(time,
                  style: const TextStyle(color: doctorMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 18),
          Text(title,
              style: const TextStyle(
                  color: doctorText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
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
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 16, color: doctorTeal),
                Text(patient,
                    style: const TextStyle(
                        color: doctorTeal, fontWeight: FontWeight.w700)),
                Text('· $meta', style: const TextStyle(color: doctorMuted)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFF50585C), fontSize: 15, height: 1.35)),
          const SizedBox(height: 28),
          Container(height: 1, color: doctorBorder),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: filledButton
                ? ElevatedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('View Patient'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: doctorTeal2,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('View Patient'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: doctorTeal,
                      side: const BorderSide(color: doctorTeal),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
