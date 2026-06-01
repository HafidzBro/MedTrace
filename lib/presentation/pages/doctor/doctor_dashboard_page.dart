import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class DoctorDashboardPage extends ConsumerWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final summary = ref.watch(currentDoctorDashboardSummaryProvider);
    final data = summary.valueOrNull;
    final doctorName = _doctorName(user?.fullName ?? 'Doctor');
    final totalPatients = data?.totalPatients.toString() ?? '0';
    final activeTherapies = data?.activeTherapies.toString() ?? '0';
    final highPriority = data?.highPriorityAlerts.toString() ?? '0';
    final recovered =
        data?.therapies.where((therapy) => therapy.isCompleted).length ?? 0;

    return DoctorMockScaffold(
      currentIndex: 0,
      appBar: DoctorTopBar(
        title: 'MedTrace',
        centeredTitle: true,
        onLeadingTap: () => context.go(AppRoutes.doctorProfile),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 30, 32, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, $doctorName',
              style: const TextStyle(
                color: doctorText,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Here is your patient overview for today.',
              style: TextStyle(color: doctorMuted, fontSize: 15),
            ),
            const SizedBox(height: 34),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.28,
              children: [
                _KpiCard(
                  title: 'TOTAL PATIENTS',
                  value: summary.isLoading ? '...' : totalPatients,
                  subtitle: 'Assigned patients',
                  icon: Icons.groups_rounded,
                ),
                _KpiCard(
                  title: 'ACTIVE\nTREATMENTS',
                  value: summary.isLoading ? '...' : activeTherapies,
                  subtitle: 'Ongoing therapies',
                  icon: Icons.medical_services_rounded,
                  dark: true,
                ),
                _KpiCard(
                  title: 'AT RISK OF\nDEFAULT',
                  value: summary.isLoading ? '...' : highPriority,
                  subtitle: 'Requires immediate\naction',
                  icon: Icons.warning_rounded,
                  danger: true,
                ),
                _KpiCard(
                  title: 'RECOVERED',
                  value: summary.isLoading ? '...' : recovered.toString(),
                  subtitle: 'Completed therapy',
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: 32),
            DoctorCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Priority Follow-ups',
                          style: TextStyle(
                            color: doctorText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz_rounded),
                        color: doctorTeal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ..._followUps(data),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.patientManagement),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: doctorTeal,
                        side: const BorderSide(color: Color(0xFFB7C3C3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'View All Patients',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _doctorName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Doctor';
    return trimmed.startsWith('Dr.')
        ? trimmed
        : 'Dr. ${trimmed.split(RegExp(r'\s+')).first}';
  }

  static List<Widget> _followUps(dynamic data) {
    final alerts = data?.alerts ?? const [];
    if (alerts.isEmpty) {
      return const [
        _FollowUpTile(
          initials: 'SJ',
          name: 'Sarah Jenkins',
          note: 'Seed patient ready for review',
          badge: 'Active',
          badgeColor: doctorMintSoft,
          badgeText: doctorTeal,
        ),
        SizedBox(height: 12),
      ];
    }

    return alerts.take(3).map<Widget>((alert) {
      final high = alert.severity == 'high' || alert.severity == 'critical';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _FollowUpTile(
          initials: 'SJ',
          name: 'Sarah Jenkins',
          note: alert.description ?? alert.type,
          badge: high ? 'High Risk' : 'Medium Risk',
          badgeColor: high ? doctorDangerSoft : doctorWarningSoft,
          badgeText: high ? doctorDanger : const Color(0xFF8C4A1F),
        ),
      );
    }).toList();
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool dark;
  final bool danger;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.dark = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark
        ? doctorTeal
        : danger
            ? doctorDangerSoft
            : Colors.white;
    final fg = dark
        ? Colors.white
        : danger
            ? doctorDanger
            : doctorText;
    final sub = dark ? const Color(0xFFA9DAD8) : doctorTeal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: danger ? const Color(0xFFFF9D9D) : doctorBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -34,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : doctorMintSoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: danger
                            ? doctorDanger
                            : (dark ? const Color(0xFFA9DAD8) : doctorMuted),
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Icon(icon,
                      color: dark
                          ? const Color(0xFFA9DAD8)
                          : (danger ? doctorDanger : doctorTeal),
                      size: 22),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: fg,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: danger ? doctorDanger : sub,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  final String initials;
  final String name;
  final String note;
  final String badge;
  final Color badgeColor;
  final Color badgeText;

  const _FollowUpTile({
    required this.initials,
    required this.name,
    required this.note,
    required this.badge,
    required this.badgeColor,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: doctorBorder),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          DoctorAvatar(
            initials: initials,
            radius: 20,
            color: doctorNeutral,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: doctorText)),
                const SizedBox(height: 2),
                Text(note,
                    style: const TextStyle(color: doctorMuted, fontSize: 14)),
              ],
            ),
          ),
          DoctorChip(label: badge, color: badgeColor, textColor: badgeText),
        ],
      ),
    );
  }
}
