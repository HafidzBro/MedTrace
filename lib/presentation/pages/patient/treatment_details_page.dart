import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/services/supabase/medication_service.dart';

class TreatmentDetailsPage extends ConsumerWidget {
  final String? patientId;

  const TreatmentDetailsPage({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentPatientDashboardSummaryProvider);
    final intakePlan = ref.watch(currentPatientIntakePlanProvider);
    final therapy = summary.valueOrNull?.therapy;
    final plan = intakePlan.valueOrNull;
    final isLoading = summary.isLoading || intakePlan.isLoading;

    return PatientMockScaffold(
      currentIndex: 1,
      appBar: PatientTopBar(
        title: 'My Progress',
        leadingIcon: Icons.person,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.go(AppRoutes.patientProfile),
              child: const PatientAvatar(icon: Icons.person, radius: 18),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: patientTeal),
                ),
              )
            else ...[
              _CurrentStatusCard(
                adherence: summary.valueOrNull?.adherencePercentage ?? 0,
                monthLabel: _monthLabel(therapy?.treatmentDaysElapsed ?? 0),
                hasTherapy: therapy != null,
              ),
              const SizedBox(height: 32),
              _PhaseCard(
                plan: plan,
                note: therapy?.description,
              ),
            ],
            const SizedBox(height: 32),
            const SectionTitle('Your Journey'),
            const SizedBox(height: 24),
            const _JourneyCard(
              state: _JourneyState.completed,
              label: 'Completed',
              when: 'Week 0',
              title: 'Initial Screening',
              body:
                  'Diagnosis confirmed and personalized treatment plan established with your care team.',
            ),
            const SizedBox(height: 20),
            _JourneyCard(
              state:
                  therapy == null ? _JourneyState.locked : _JourneyState.active,
              label: 'In Progress',
              when: _monthLabel(therapy?.treatmentDaysElapsed ?? 0),
              title: plan?.phaseName ?? 'Treatment Phase',
              body: plan?.instructionLabel ??
                  'Your active treatment phase will appear after therapy starts.',
            ),
            const SizedBox(height: 20),
            _JourneyCard(
              state: (therapy?.treatmentDaysElapsed ?? 0) >= 60
                  ? _JourneyState.active
                  : _JourneyState.upcoming,
              label: 'Upcoming',
              when: 'Month 2',
              title: 'Phase Transition',
              body:
                  'Assessment to transition from Intensive to Continuation phase based on lab results.',
            ),
            const SizedBox(height: 20),
            const _JourneyCard(
              state: _JourneyState.locked,
              label: 'Locked',
              when: 'Month 6',
              title: 'Treatment Completion',
              body:
                  'Final evaluation and confirmation of successful therapy completion.',
            ),
          ],
        ),
      ),
    );
  }

  String _monthLabel(int days) {
    if (days <= 0) return 'Month 1 of 6';
    final month = ((days ~/ 30) + 1).clamp(1, 6);
    return 'Month $month of 6';
  }
}

class _CurrentStatusCard extends StatelessWidget {
  final double adherence;
  final String monthLabel;
  final bool hasTherapy;

  const _CurrentStatusCard({
    required this.adherence,
    required this.monthLabel,
    required this.hasTherapy,
  });

  @override
  Widget build(BuildContext context) {
    return PatientCard(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -78,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: patientMintSoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Status',
                style: TextStyle(
                  color: patientText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  PatientChip(
                    label: hasTherapy
                        ? adherence >= 80
                            ? 'On Track'
                            : adherence >= 60
                                ? 'Needs Attention'
                                : 'At Risk'
                        : 'Not Started',
                    icon: hasTherapy
                        ? adherence >= 60
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded
                        : Icons.hourglass_empty_rounded,
                    color: hasTherapy && adherence >= 60
                        ? const Color(0xFFDDF3E5)
                        : const Color(0xFFFFE7D6),
                    textColor: hasTherapy && adherence >= 60
                        ? const Color(0xFF177C38)
                        : const Color(0xFFAD4B00),
                  ),
                  Text(
                    monthLabel,
                    style: const TextStyle(color: patientMuted, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasTherapy
                    ? 'Your treatment progress is calculated from therapy start date and daily medication logs.'
                    : 'Your therapy has not started yet. Your care team will configure the treatment plan.',
                style: const TextStyle(
                  color: Color(0xFF50585C),
                  fontSize: 16,
                  height: 1.48,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final MedicationIntakePlan? plan;
  final String? note;

  const _PhaseCard({
    required this.plan,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: patientTeal2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_liquid_rounded,
                  color: Color(0xFFA8DDDA), size: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan?.phaseName ?? 'No Active Phase',
                      style: const TextStyle(
                        color: Color(0xFFA8DDDA),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan?.monthRangeLabel ?? 'Waiting for therapy setup',
                      style: const TextStyle(
                        color: Color(0xFFA8DDDA),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            plan?.instructionLabel ??
                'Your phase instructions will appear after therapy is configured.',
            style: const TextStyle(
              color: Color(0xFFA8DDDA),
              fontSize: 16,
              height: 1.52,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PatientAvatar(icon: Icons.person, radius: 20),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A note from Dr. Sarah',
                        style: TextStyle(
                          color: Color(0xFFA8DDDA),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note?.trim().isNotEmpty == true
                            ? note!.trim()
                            : 'Keep following your daily medication schedule. Contact your doctor if you experience unexpected symptoms.',
                        style: const TextStyle(
                          color: Color(0xFFA8DDDA),
                          fontSize: 14,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _JourneyState { completed, active, upcoming, locked }

class _JourneyCard extends StatelessWidget {
  final _JourneyState state;
  final String label;
  final String when;
  final String title;
  final String body;

  const _JourneyCard({
    required this.state,
    required this.label,
    required this.when,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final active = state == _JourneyState.active;
    final completed = state == _JourneyState.completed;
    final disabled =
        state == _JourneyState.upcoming || state == _JourneyState.locked;
    final color = completed || active ? patientTeal : const Color(0xFF9EA7AA);
    final border = completed
        ? patientMint
        : active
            ? patientTeal
            : patientBorder;

    return PatientCard(
      padding: const EdgeInsets.all(20),
      borderColor: border,
      child: Container(
        decoration: active || completed
            ? const BoxDecoration(
                border: Border(left: BorderSide(color: patientTeal, width: 5)),
              )
            : null,
        padding: EdgeInsets.only(left: active || completed ? 14 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed
                      ? Icons.check_circle
                      : active
                          ? Icons.radio_button_checked
                          : state == _JourneyState.locked
                              ? Icons.lock_outline
                              : Icons.radio_button_unchecked,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  when,
                  style: const TextStyle(color: patientMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: disabled ? const Color(0xFF777E80) : patientText,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              style: TextStyle(
                color: disabled ? const Color(0xFF888F91) : patientMuted,
                fontSize: 14,
                height: 1.38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
