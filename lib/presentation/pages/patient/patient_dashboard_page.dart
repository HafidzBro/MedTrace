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
    final firstName = _firstName(user?.fullName ?? user?.email ?? 'Patient');

    return PatientMockScaffold(
      currentIndex: 0,
      appBar: PatientTopBar(
        title: 'Good Morning',
        leadingIcon: Icons.person,
        onLeadingTap: () => context.go(AppRoutes.patientProfile),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              PatientCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_graph_rounded, color: patientTeal),
                        SizedBox(width: 10),
                        Expanded(
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
                          'Month 2 of 6',
                          style: TextStyle(
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
                      child: const LinearProgressIndicator(
                        value: 0.34,
                        minHeight: 12,
                        backgroundColor: patientNeutral,
                        valueColor: AlwaysStoppedAnimation(patientTeal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _MedicineCard(onLogDose: () => context.go(AppRoutes.reminders)),
              const SizedBox(height: 32),
              const SectionTitle('Weekly Adherence'),
              const SizedBox(height: 12),
              const PatientCard(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DayDot(day: 'M', status: _DayStatus.done),
                    _DayDot(day: 'T', status: _DayStatus.done),
                    _DayDot(day: 'W', status: _DayStatus.current),
                    _DayDot(day: 'T'),
                    _DayDot(day: 'F'),
                    _DayDot(day: 'S'),
                    _DayDot(day: 'S'),
                  ],
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
    );
  }

  static String _firstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Patient';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _MedicineCard extends StatelessWidget {
  final VoidCallback onLogDose;

  const _MedicineCard({required this.onLogDose});

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
              const PatientChip(
                label: 'Today, 08:00 AM',
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
              onPressed: onLogDose,
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

enum _DayStatus { empty, done, current }

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
    final current = status == _DayStatus.current;
    return Column(
      children: [
        Text(day, style: const TextStyle(color: patientMuted, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filled ? patientMint : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: current ? patientTeal : patientBorder,
              width: current ? 2 : 1,
            ),
          ),
          child: Icon(
            filled
                ? Icons.check_rounded
                : current
                    ? Icons.circle
                    : null,
            size: filled ? 18 : 10,
            color: patientTeal,
          ),
        ),
      ],
    );
  }
}
