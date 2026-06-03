import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/services/supabase/medication_service.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final intakePlan = ref.watch(currentPatientIntakePlanProvider);

    return PatientMockScaffold(
      currentIndex: 2,
      backgroundColor: const Color(0xFFF0FBFA),
      child: SafeArea(
        child: RefreshIndicator(
          color: patientTeal,
          onRefresh: () => _refresh(ref),
          child: intakePlan.when(
            loading: () => const _RefreshableReminderCenter(
              child: CircularProgressIndicator(color: patientTeal),
            ),
            error: (error, _) => _RefreshableReminderCenter(
              child: _ReminderMessage(
                title: 'Reminder unavailable',
                message: error.toString(),
              ),
            ),
            data: (plan) => _ReminderContent(
              plan: plan,
              onConfirm: plan == null ||
                      plan.items.isEmpty ||
                      plan.isTakenToday ||
                      user == null
                  ? null
                  : () => _confirmIntake(
                        context,
                        ref,
                        user.id,
                        plan.intakeTime,
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(currentPatientDashboardSummaryProvider);
    ref.invalidate(currentPatientIntakePlanProvider);
    ref.invalidate(currentPatientAdherenceHistoryProvider);
    await ref.read(currentPatientIntakePlanProvider.future);
  }

  Future<void> _confirmIntake(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    DateTime? reminderTime,
  ) async {
    try {
      await ref.read(supabaseServiceProvider).logTodayDose(patientId);
      ref.invalidate(currentPatientDashboardSummaryProvider);
      ref.invalidate(currentPatientIntakePlanProvider);
      if (!context.mounted) return;
      _showDoseLogged(context, DateTime.now(), reminderTime);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showDoseLogged(
    BuildContext context,
    DateTime timestamp,
    DateTime? reminderTime,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: patientBorder, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: patientMint.withValues(alpha: 0.35),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 42),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Dose Logged!',
                  style: TextStyle(fontSize: 16, color: patientText),
                ),
                const SizedBox(height: 4),
                Text(
                  'Great job staying on track. Your next dose is scheduled for tomorrow at ${_formatClock(reminderTime ?? DateTime(0, 1, 1, 8))}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: patientText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: patientBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'INTAKE TIMESTAMP',
                        style: TextStyle(
                          color: patientText,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(timestamp),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.patientDashboard);
                    },
                    child: const Text(
                      'Return to Home',
                      style: TextStyle(color: patientText, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatTimestamp(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Today, $hour:$minute';
  }

  static String _formatClock(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }
}

class _RefreshableReminderCenter extends StatelessWidget {
  final Widget child;

  const _RefreshableReminderCenter({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Center(child: child),
      ),
    );
  }
}

class _ReminderContent extends StatelessWidget {
  final MedicationIntakePlan? plan;
  final VoidCallback? onConfirm;

  const _ReminderContent({
    required this.plan,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final activePlan = plan;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 12, 36, 104),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 128),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: patientTeal2,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: patientTeal.withValues(alpha: 0.24),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    color: Color(0xFFA9DAD8),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Time for your ${_timeOfDayLabel(activePlan?.intakeTime)}\ndose',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: patientTeal,
                    fontSize: 30,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  activePlan == null
                      ? 'No active medication schedule is available yet.'
                      : '${activePlan.phaseName} treatment plan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF50585C),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 34),
                _MedicationCard(plan: activePlan),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      activePlan?.isTakenToday == true
                          ? 'Intake Confirmed'
                          : 'Confirm Intake',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: patientTeal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFBFCBCB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeOfDayLabel(DateTime? time) {
    final hour = time?.hour ?? 8;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _MedicationCard extends StatelessWidget {
  final MedicationIntakePlan? plan;

  const _MedicationCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final activePlan = plan;
    return PatientCard(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      color: Colors.white,
      borderColor: const Color(0xFFD1F5EF),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: patientMint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: patientTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activePlan?.medicationLabel ?? 'Medication not assigned',
                      style: const TextStyle(
                        color: patientTeal,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      activePlan?.dosageLabel ?? 'Waiting for doctor setup',
                      style: const TextStyle(
                        color: Color(0xFF50585C),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: patientBorder),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: patientTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activePlan?.instructionLabel ??
                        'Your medication details will appear after the doctor configures your treatment phase.',
                    style: const TextStyle(
                      color: patientText,
                      fontSize: 15,
                      height: 1.35,
                    ),
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

class _ReminderMessage extends StatelessWidget {
  final String title;
  final String message;

  const _ReminderMessage({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, color: patientTeal, size: 52),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: patientText,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF50585C), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
