import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class TreatmentDetailsPage extends ConsumerWidget {
  final String? patientId;

  const TreatmentDetailsPage({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(36, 32, 36, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentStatusCard(),
            SizedBox(height: 32),
            _PhaseCard(),
            SizedBox(height: 32),
            SectionTitle('Your Journey'),
            SizedBox(height: 24),
            _JourneyCard(
              state: _JourneyState.completed,
              label: 'Completed',
              when: 'Week 0',
              title: 'Initial Screening',
              body:
                  'Diagnosis confirmed and personalized treatment plan established with your care team.',
            ),
            SizedBox(height: 20),
            _JourneyCard(
              state: _JourneyState.active,
              label: 'In Progress',
              when: 'Month 1',
              title: 'Month 1 Check-up',
              body:
                  'Evaluating your response to the initial medication. Lab results pending review.',
            ),
            SizedBox(height: 20),
            _JourneyCard(
              state: _JourneyState.upcoming,
              label: 'Upcoming',
              when: 'Month 2',
              title: 'Phase Transition',
              body:
                  'Assessment to transition from Intensive to Continuation phase based on lab results.',
            ),
            SizedBox(height: 20),
            _JourneyCard(
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
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard();

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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status',
                style: TextStyle(
                  color: patientText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  PatientChip(
                    label: 'On Track',
                    icon: Icons.check_circle,
                    color: Color(0xFFDDF3E5),
                    textColor: Color(0xFF177C38),
                  ),
                  Text(
                    'Month 1 of 6',
                    style: TextStyle(color: patientMuted, fontSize: 15),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'You are doing wonderfully. Consistency is key, and you are building a strong foundation for recovery.',
                style: TextStyle(
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
  const _PhaseCard();

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
          const Row(
            children: [
              Icon(Icons.medication_liquid_rounded,
                  color: Color(0xFFA8DDDA), size: 34),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intensive Phase',
                      style: TextStyle(
                        color: Color(0xFFA8DDDA),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '0 - 2 Months',
                      style: TextStyle(
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
          const Text(
            'During these first two months, the goal is to rapidly reduce the bacteria. It is normal to feel tired. Your body is working hard to heal.',
            style: TextStyle(
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
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PatientAvatar(icon: Icons.person, radius: 20),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A note from Dr. Sarah',
                        style: TextStyle(
                          color: Color(0xFFA8DDDA),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '"I am very pleased with your early progress. Keep up the daily routines, and reach out if you experience any unexpected side effects."',
                        style: TextStyle(
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
