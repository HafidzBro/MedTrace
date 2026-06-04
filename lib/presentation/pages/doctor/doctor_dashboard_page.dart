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
      child: RefreshIndicator(
        color: doctorTeal,
        onRefresh: () => _refresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_timeGreeting()}, $doctorName',
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 128,
                ),
                itemBuilder: (context, index) {
                  final cards = [
                    _KpiCard(
                      title: 'TOTAL\nPATIENTS',
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
                      subtitle: 'Immediate action',
                      icon: Icons.warning_rounded,
                      danger: true,
                    ),
                    _KpiCard(
                      title: 'RECOVERED',
                      value: summary.isLoading ? '...' : recovered.toString(),
                      subtitle: 'Completed therapy',
                      icon: Icons.check_circle_rounded,
                    ),
                  ];
                  return cards[index];
                },
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
                    ..._followUps(data, isLoading: summary.isLoading),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () =>
                            context.go(AppRoutes.patientManagement),
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
      ),
    );
  }

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(currentDoctorDashboardSummaryProvider);
    ref.invalidate(currentDoctorMapSummaryProvider);
    await ref.read(currentDoctorDashboardSummaryProvider.future);
  }

  static String _doctorName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Doctor';
    return trimmed.startsWith('Dr.')
        ? trimmed
        : 'Dr. ${trimmed.split(RegExp(r'\s+')).first}';
  }

  static List<Widget> _followUps(dynamic data, {required bool isLoading}) {
    final alerts = data?.alerts ?? const [];
    if (isLoading) {
      return const [
        _EmptyFollowUpTile(
          icon: Icons.hourglass_empty_rounded,
          title: 'Loading follow-ups',
          message: 'Checking alerts from your assigned patients.',
        ),
      ];
    }

    if (alerts.isEmpty) {
      return const [
        _EmptyFollowUpTile(
          icon: Icons.check_circle_outline_rounded,
          title: 'No priority follow-ups',
          message: 'New patient alerts will appear here.',
        ),
      ];
    }

    return alerts.take(3).map<Widget>((alert) {
      final high = alert.severity == 'high' || alert.severity == 'critical';
      final patientName = _patientDisplayName(
        alert.patientName,
        alert.patientEmail,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _FollowUpTile(
          initials: _initials(patientName),
          name: patientName,
          note: alert.description ?? _formatAlertType(alert.type),
          badge: high ? 'High Risk' : 'Medium Risk',
          badgeColor: high ? doctorDangerSoft : doctorWarningSoft,
          badgeText: high ? doctorDanger : const Color(0xFF8C4A1F),
        ),
      );
    }).toList();
  }

  static String _patientDisplayName(String? name, String? email) {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) return trimmedEmail;
    return 'Patient';
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PT';
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }

  static String _formatAlertType(String value) {
    final words = value
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');
    return words.join(' ');
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
      padding: const EdgeInsets.all(14),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: danger
                            ? doctorDanger
                            : (dark ? const Color(0xFFA9DAD8) : doctorMuted),
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Icon(icon,
                      color: dark
                          ? const Color(0xFFA9DAD8)
                          : (danger ? doctorDanger : doctorTeal),
                      size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  color: fg,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: danger ? doctorDanger : sub,
                  fontSize: 11,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: doctorBorder),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DoctorAvatar(
                initials: initials,
                radius: 20,
                color: doctorNeutral,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: doctorText,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              color: doctorMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: DoctorChip(
              label: badge,
              color: badgeColor,
              textColor: badgeText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFollowUpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyFollowUpTile({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F4),
        border: Border.all(color: doctorBorder),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(icon, color: doctorTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: doctorText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(color: doctorMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
