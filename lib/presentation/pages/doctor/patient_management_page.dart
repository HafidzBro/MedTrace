import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class PatientManagementPage extends StatelessWidget {
  const PatientManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DoctorMockScaffold(
      currentIndex: 1,
      appBar: const DoctorTopBar(
        title: 'MedTrace',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: DoctorAvatar(
                icon: Icons.person, radius: 18, color: Color(0xFF2F3D4A)),
          ),
          SizedBox(width: 4),
          Icon(Icons.notifications_none_rounded, color: doctorTeal),
          SizedBox(width: 18),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Directory',
              style: TextStyle(
                color: doctorText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage and monitor active therapy regimens.',
              style: TextStyle(color: doctorMuted, fontSize: 15),
            ),
            const SizedBox(height: 34),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFB7C3C3)),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: Color(0xFF657174)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search by name, ID, or phone...',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Color(0xFF7B8588), fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFB7C3C3)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child:
                      const Icon(Icons.filter_list_rounded, color: doctorText),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PatientDirectoryCard(
              initials: 'AM',
              name: 'Amina',
              id: 'TBM-23-0842',
              status: 'On Treatment',
              statusColor: doctorMintSoft,
              statusText: doctorTeal,
              days: '112',
              totalDays: '180',
              progress: 0.62,
              lastLog: 'Today, 08:30',
              lastLogIcon: Icons.check_circle_outline_rounded,
              avatarColor: doctorTeal2,
              onTap: () => context
                  .go(AppRoutes.patientDetail, extra: {'patientName': 'Amina'}),
            ),
            const SizedBox(height: 18),
            _PatientDirectoryCard(
              initials: 'DK',
              name: 'David',
              id: 'TBM-23-1105',
              status: 'At Risk (3 Missed)',
              statusColor: doctorDangerSoft,
              statusText: doctorDanger,
              days: '45',
              totalDays: '180',
              progress: 0.2,
              progressColor: doctorDanger,
              lastLog: '3 days ago',
              lastLogIcon: Icons.warning_amber_rounded,
              lastLogColor: doctorDanger,
              avatarColor: doctorDangerSoft,
              avatarText: doctorDanger,
              onTap: () => context
                  .go(AppRoutes.patientDetail, extra: {'patientName': 'David'}),
            ),
            const SizedBox(height: 18),
            _PatientDirectoryCard(
              initials: 'SJ',
              name: 'Sarah',
              id: 'TBM-24-0012',
              status: 'Pending Sputum Test',
              statusColor: doctorNeutral,
              statusText: const Color(0xFF4F585B),
              days: '14',
              totalDays: '180',
              progress: 0.08,
              progressColor: const Color(0xFF7D8788),
              lastLog: 'Yesterday',
              lastLogIcon: Icons.check_circle_outline_rounded,
              avatarColor: doctorNeutral,
              avatarText: const Color(0xFF5D6668),
              onTap: () => context
                  .go(AppRoutes.patientDetail, extra: {'patientName': 'Sarah'}),
            ),
            const SizedBox(height: 18),
            _PatientDirectoryCard(
              initials: 'EO',
              name: 'Emmanuel',
              id: 'TBM-23-0551',
              status: 'On Treatment',
              statusColor: doctorMintSoft,
              statusText: doctorTeal,
              days: '165',
              totalDays: '180',
              progress: 0.9,
              lastLog: 'Today, 06:15',
              lastLogIcon: Icons.check_circle_outline_rounded,
              avatarColor: doctorTeal2,
              onTap: () => context.go(AppRoutes.patientDetail,
                  extra: {'patientName': 'Emmanuel'}),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientDirectoryCard extends StatelessWidget {
  final String initials;
  final String name;
  final String id;
  final String status;
  final Color statusColor;
  final Color statusText;
  final String days;
  final String totalDays;
  final double progress;
  final Color progressColor;
  final String lastLog;
  final IconData lastLogIcon;
  final Color lastLogColor;
  final Color avatarColor;
  final Color avatarText;
  final VoidCallback onTap;

  const _PatientDirectoryCard({
    required this.initials,
    required this.name,
    required this.id,
    required this.status,
    required this.statusColor,
    required this.statusText,
    required this.days,
    required this.totalDays,
    required this.progress,
    this.progressColor = doctorTeal2,
    required this.lastLog,
    required this.lastLogIcon,
    this.lastLogColor = doctorTeal,
    required this.avatarColor,
    this.avatarText = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: DoctorCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: avatarText,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: doctorText,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('ID: $id',
                          style:
                              const TextStyle(color: doctorText, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DoctorChip(
              label: status,
              icon: Icons.circle,
              color: statusColor,
              textColor: statusText,
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: doctorBorder),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Days on Therapy',
                          style: TextStyle(color: doctorMuted, fontSize: 13)),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: doctorText),
                          children: [
                            TextSpan(
                                text: days,
                                style: const TextStyle(
                                    fontSize: 21, fontWeight: FontWeight.w800)),
                            TextSpan(
                                text: ' / $totalDays',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: doctorNeutral,
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Log',
                          style: TextStyle(color: doctorMuted, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(lastLogIcon, size: 16, color: lastLogColor),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(lastLog,
                                  style: const TextStyle(
                                      color: doctorText, fontSize: 14))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
