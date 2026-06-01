import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medtrace/data/models/therapy_status_history_model.dart';
import 'package:medtrace/services/supabase/medication_service.dart';
import 'package:medtrace/services/supabase_service.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class PatientDetailPage extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const PatientDetailPage({
    required this.patientId,
    required this.patientName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(patientDetailSummaryProvider(patientId));
    final summary = summaryState.valueOrNull;
    final displayName = summary == null
        ? _fallbackPatientName(patientName)
        : _patientName(summary);

    return Scaffold(
      backgroundColor: doctorBg,
      appBar: DoctorTopBar(
        title: 'Patient Detail',
        showBack: true,
        onLeadingTap: () => context.go(AppRoutes.patientManagement),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: doctorTeal,
            onRefresh: () async {
              ref.invalidate(patientDetailSummaryProvider(patientId));
              await ref.read(patientDetailSummaryProvider(patientId).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 96),
              children: [
                if (summaryState.hasError && summary == null)
                  _StateCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load patient',
                    message: summaryState.error.toString(),
                    danger: true,
                  )
                else ...[
                  _ProfileCard(
                    name: displayName,
                    summary: summary,
                    isLoading: summaryState.isLoading,
                  ),
                  const SizedBox(height: 26),
                  _IdentitySummary(summary: summary),
                  const SizedBox(height: 26),
                  _DiagnosisCard(summary: summary),
                  const SizedBox(height: 26),
                  _TherapyPhaseCard(
                    summary: summary,
                    onReset: summary == null || summary.therapy == null
                        ? null
                        : () => _confirmResetTherapy(context, ref, summary),
                  ),
                  const SizedBox(height: 26),
                  _MedicationScheduleCard(summary: summary),
                  const SizedBox(height: 26),
                  _TherapyHistoryCard(summary: summary),
                ],
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: summary == null || summary.therapy == null
                      ? null
                      : () => _showUpdateStatusSheet(context, summary),
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('Update Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: doctorTeal2,
                    foregroundColor: const Color(0xFFA9DAD8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetTherapy(
    BuildContext context,
    WidgetRef ref,
    PatientDetailSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset therapy progress?'),
        content: const Text(
          'This will move the current therapy back to day 1, reset adherence progress, and restart the phase schedule. Medication history remains available for audit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: doctorDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(supabaseServiceProvider)
          .resetTherapyProgress(summary.therapy!.id);
      ref.invalidate(patientDetailSummaryProvider(patientId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapy progress reset to day 1.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset therapy: $error')),
      );
    }
  }

  void _showUpdateStatusSheet(
    BuildContext context,
    PatientDetailSummary summary,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _UpdateStatusSheet(
        patientId: patientId,
        summary: summary,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final PatientDetailSummary? summary;
  final bool isLoading;

  const _ProfileCard({
    required this.name,
    required this.summary,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final patient = summary?.patient;
    final status = _statusLabel(summary);
    final demographics = _demographics(summary);

    return DoctorCard(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              DoctorAvatar(
                initials: _initials(name),
                icon: Icons.person,
                radius: 44,
                color: const Color(0xFF16A39A),
              ),
              Positioned(
                right: -4,
                bottom: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: doctorTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: doctorMint,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: doctorText,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoading
                ? 'Loading patient...'
                : 'ID: ${patient?.patientCode?.trim().isNotEmpty == true ? patient!.patientCode : _shortId(patient?.patientId)}',
            style: const TextStyle(color: doctorMuted, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              DoctorChip(
                label: status,
                icon: Icons.check_circle_outline_rounded,
                color: doctorMintSoft,
                textColor: doctorTeal,
              ),
              if (demographics != null)
                DoctorChip(
                  label: demographics,
                  color: doctorNeutral,
                  textColor: const Color(0xFF5C6567),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentitySummary extends StatelessWidget {
  final PatientDetailSummary? summary;

  const _IdentitySummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final patient = summary?.patient;
    final profile = summary?.profile;

    return DoctorCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.person_outline_rounded,
            title: 'Identity Summary',
          ),
          const SizedBox(height: 22),
          _DetailRow(label: 'DOB', value: _dateOrEmpty(patient?.birthDate)),
          const _Line(),
          _DetailRow(label: 'Age', value: _ageLabel(patient?.birthDate)),
          const _Line(),
          _DetailRow(
              label: 'Contact', value: _textOrEmpty(profile?.phoneNumber)),
          const _Line(),
          _DetailRow(label: 'Address', value: _textOrEmpty(patient?.address)),
        ],
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final PatientDetailSummary? summary;

  const _DiagnosisCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tbCase = summary?.tbCase;
    return DoctorCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.medical_information_outlined,
            title: 'Diagnosis',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F6),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: doctorBorder),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'CATEGORY',
                  value: _tbCategoryLabel(tbCase?.tbCategory),
                  valueColor: doctorTeal,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'DATE DIAGNOSED',
                  value: _dateOrEmpty(tbCase?.diagnosisDate),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'TYPE',
                  value: _diagnosisTypeLabel(tbCase?.tbType),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TherapyPhaseCard extends StatelessWidget {
  final PatientDetailSummary? summary;
  final VoidCallback? onReset;

  const _TherapyPhaseCard({
    required this.summary,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final therapy = summary?.therapy;
    final days = therapy?.treatmentDaysElapsed.clamp(0, 180) ?? 0;
    final progress = (days / 180).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final phase = _phaseLabel(days);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: doctorTeal2,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: doctorTeal.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current Therapy Phase',
                  style: TextStyle(
                    color: Color(0xFFA9DAD8),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE12835),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            therapy == null ? 'No active therapy' : phase,
            style: const TextStyle(color: Color(0xFFA9DAD8), fontSize: 15),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overall Progress',
                  style: TextStyle(color: Color(0xFFA9DAD8), fontSize: 14),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Color(0xFFA9DAD8),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DoctorChip(
            label: therapy == null ? 'Not Started' : _statusLabel(summary),
            color: const Color(0xFF5C9D9F),
            textColor: const Color(0xFFCBE9E7),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFF005256),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationScheduleCard extends StatelessWidget {
  final PatientDetailSummary? summary;

  const _MedicationScheduleCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final therapy = summary?.therapy;
    final plan = summary?.intakePlan;
    final days = therapy?.treatmentDaysElapsed ?? 0;
    final meds = _medicationItems(plan, days);
    final intakeTime = _formatTime(plan?.intakeTime) ?? '08:00 AM';
    final adherence = therapy?.adherencePercentage;

    return DoctorCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: doctorTeal),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Medication\nSchedule',
                  style: TextStyle(
                    color: doctorText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
              Text(
                'Current Phase\nAdherence: ${adherence == null ? '-' : '${adherence.toStringAsFixed(0)}%'}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: doctorMuted,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...meds.map(
                    (med) => SizedBox(
                      width: tileWidth,
                      child: _MedBox(
                        label: med.name,
                        value: med.dose,
                        icon: Icons.medication_rounded,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: const _MedBox(
                      label: 'Frequency',
                      value: 'Daily',
                      icon: Icons.update_rounded,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _MedBox(
                      label: 'Next Dose',
                      value: intakeTime,
                      icon: Icons.alarm_rounded,
                      filled: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TherapyHistoryCard extends StatelessWidget {
  final PatientDetailSummary? summary;

  const _TherapyHistoryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final histories =
        summary?.statusHistory ?? const <TherapyStatusHistoryModel>[];

    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.history_rounded, title: 'Therapy History'),
          const SizedBox(height: 24),
          if (histories.isEmpty)
            const Text(
              'Therapy status changes will appear here after a doctor update.',
              style: TextStyle(color: doctorMuted, fontSize: 14, height: 1.35),
            )
          else
            ...histories.take(7).map(
                  (history) => _TimelineItem(
                    icon: _statusHistoryIcon(history.newStatus),
                    title: _statusHistoryTitle(history),
                    time: _statusHistoryTime(history),
                    body: _statusHistoryBody(history),
                    active: history == histories.first,
                  ),
                ),
        ],
      ),
    );
  }
}

class _UpdateStatusSheet extends ConsumerStatefulWidget {
  final String patientId;
  final PatientDetailSummary summary;

  const _UpdateStatusSheet({
    required this.patientId,
    required this.summary,
  });

  @override
  ConsumerState<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<_UpdateStatusSheet> {
  final _notesController = TextEditingController();
  final _notesFocusNode = FocusNode();
  late String _selectedStatusKey;
  bool _isSaving = false;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    _selectedStatusKey = _statusKeyFromDatabase(
        widget.summary.therapy?.status ?? 'on_treatment');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: doctorBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Therapy Status',
                          style: TextStyle(
                            color: doctorText,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Record a change in the patient clinical pathway.',
                          style: TextStyle(color: doctorMuted, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB7C3C3)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Current Status',
                        style:
                            TextStyle(color: Color(0xFF50585C), fontSize: 15),
                      ),
                    ),
                    DoctorChip(
                      label: _therapyStatus(widget.summary.therapy!.status)
                          .toUpperCase(),
                      icon: Icons.medication_liquid_rounded,
                      color: doctorTeal2,
                      textColor: const Color(0xFFA9DAD8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Select New Status',
                style: TextStyle(
                  color: doctorText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.85,
                children: [
                  _StatusChoice(
                    icon: Icons.medication_liquid_rounded,
                    label: 'On Treatment',
                    selected: _selectedStatusKey == 'on_treatment',
                    onTap: () =>
                        setState(() => _selectedStatusKey = 'on_treatment'),
                  ),
                  _StatusChoice(
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'Paused',
                    selected: _selectedStatusKey == 'paused',
                    onTap: () => setState(() => _selectedStatusKey = 'paused'),
                  ),
                  _StatusChoice(
                    icon: Icons.warning_amber_rounded,
                    label: 'At Risk',
                    selected: _selectedStatusKey == 'at_risk',
                    onTap: () => setState(() => _selectedStatusKey = 'at_risk'),
                  ),
                  _StatusChoice(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Completed',
                    selected: _selectedStatusKey == 'completed',
                    onTap: () =>
                        setState(() => _selectedStatusKey = 'completed'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Status Change Notes',
                      style: TextStyle(
                        color: doctorText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text('*Required', style: TextStyle(color: doctorMuted)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                maxLines: 4,
                onChanged: (_) {
                  if (_notesError == null) return;
                  setState(() => _notesError = null);
                },
                decoration: InputDecoration(
                  hintText:
                      'Enter clinical rationale for this status update...',
                  hintStyle: const TextStyle(color: Color(0xFF8A9496)),
                  errorText: _notesError,
                  filled: true,
                  fillColor: const Color(0xFFF7FAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(color: Color(0xFFB7C3C3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(color: Color(0xFFB7C3C3)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: doctorTeal, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveStatus,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Confirm Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: doctorTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveStatus() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      setState(() => _notesError = 'Status change notes are required.');
      _notesFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status change notes are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final databaseStatus = _statusKeyToDatabase(_selectedStatusKey);
      await ref.read(supabaseServiceProvider).updateTreatment(
            treatmentId: widget.summary.therapy!.id,
            status: databaseStatus,
            historyStatus:
                _selectedStatusKey == 'at_risk' ? 'at_risk' : databaseStatus,
            notes: notes,
          );
      ref.invalidate(patientDetailSummaryProvider(widget.patientId));
      ref.invalidate(currentDoctorDashboardSummaryProvider);
      await ref.read(patientDetailSummaryProvider(widget.patientId).future);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapy status updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _statusKeyFromDatabase(String status) {
    return switch (status) {
      'completed' => 'completed',
      'paused' => 'paused',
      'defaulted' => 'paused',
      'at_risk' => 'at_risk',
      _ => 'on_treatment',
    };
  }

  String _statusKeyToDatabase(String statusKey) {
    return switch (statusKey) {
      'completed' => 'completed',
      'paused' => 'paused',
      'at_risk' => 'paused',
      _ => 'on_treatment',
    };
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: doctorTeal, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: doctorText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? doctorTeal : const Color(0xFFB7C3C3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? doctorTeal : const Color(0xFF6B7275),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? doctorTeal : const Color(0xFF50585C),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = doctorText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: doctorMuted, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: doctorBorder),
    );
  }
}

class _MedBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool filled;

  const _MedBox({
    required this.label,
    required this.value,
    required this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: filled ? doctorNeutral : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: doctorBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: doctorMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: doctorText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            icon,
            color: filled ? const Color(0xFF4F585B) : doctorTeal,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String body;
  final bool active;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.body,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: active ? doctorTeal2 : doctorNeutral,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: active ? Colors.white : const Color(0xFF6B7275),
                  size: 15,
                ),
              ),
              Expanded(child: Container(width: 1, color: doctorBorder)),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(color: doctorMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: doctorText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: const TextStyle(
                      color: doctorMuted,
                      fontSize: 14,
                      height: 1.38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool danger;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(18),
      color: danger ? doctorDangerSoft : Colors.white,
      child: Row(
        children: [
          Icon(icon, color: danger ? doctorDanger : doctorTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: danger ? doctorDanger : doctorText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: danger ? doctorDanger : doctorMuted,
                    fontSize: 13,
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

class _MedicationDisplay {
  final String name;
  final String dose;

  const _MedicationDisplay(this.name, this.dose);
}

String _fallbackPatientName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == 'Patient') return 'Patient';
  return trimmed;
}

String _patientName(PatientDetailSummary summary) {
  final name = summary.profile.fullName.trim();
  if (name.isNotEmpty) return name;
  final email = summary.profile.email.trim();
  return email.isNotEmpty ? email : 'Patient';
}

String _initials(String value) {
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

String _shortId(String? value) {
  if (value == null || value.trim().isEmpty) return 'Not available';
  final compact = value.replaceAll('-', '').toUpperCase();
  if (compact.length <= 8) return compact;
  return 'PT-${compact.substring(compact.length - 8)}';
}

String? _demographics(PatientDetailSummary? summary) {
  final gender = summary?.patient.gender;
  final age = _age(summary?.patient.birthDate);
  if ((gender == null || gender.isEmpty) && age == null) return null;
  final genderLabel = gender == null || gender.isEmpty
      ? null
      : '${gender[0].toUpperCase()}${gender.substring(1)}';
  final ageLabel = age == null ? null : '$age y/o';
  return [genderLabel, ageLabel].whereType<String>().join(', ');
}

String _statusLabel(PatientDetailSummary? summary) {
  final therapy = summary?.therapy;
  if (therapy == null) return 'No Active Therapy';
  if (therapy.isCompleted) return 'Completed';
  if (_isAtRisk(summary)) return 'At Risk';
  return _therapyStatus(therapy.status);
}

String _therapyStatus(String status) {
  return switch (status) {
    'on_treatment' || 'ongoing' => 'On Treatment',
    'completed' => 'Completed',
    'defaulted' => 'Paused',
    'paused' => 'Paused',
    'at_risk' => 'At Risk',
    _ => 'Registered',
  };
}

bool _isAtRisk(PatientDetailSummary? summary) {
  final therapy = summary?.therapy;
  if (therapy == null) return false;
  if (therapy.isCompleted) return false;
  if (therapy.isDefaulted) return true;
  if (therapy.isOngoing && therapy.adherencePercentage < 80) return true;
  return summary?.recentLogs.any((log) => log.isMissed) ?? false;
}

String _dateOrEmpty(DateTime? date) {
  if (date == null) return 'Not available';
  return DateFormat('d MMM yyyy').format(date);
}

String _textOrEmpty(String? value) {
  if (value == null || value.trim().isEmpty) return 'Not available';
  return value.trim();
}

String _diagnosisTypeLabel(String? value) {
  if (value == null || value.trim().isEmpty) return 'Not available';
  return value.trim();
}

int? _age(DateTime? birthDate) {
  if (birthDate == null) return null;
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}

String _ageLabel(DateTime? birthDate) {
  final age = _age(birthDate);
  return age == null ? 'Not available' : '$age years';
}

String _tbCategoryLabel(String? value) {
  return switch (value) {
    'pulmonary' => 'Pulmonary TB',
    'extra_pulmonary' => 'Extra-pulmonary TB',
    'relapse' => 'Relapse',
    'new_case' => 'New Case',
    null || '' => 'Not available',
    _ => value
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' '),
  };
}

String _phaseLabel(int days) {
  final month = ((days <= 0 ? 1 : days) / 30).ceil().clamp(1, 6);
  if (month <= 2) return 'Intensive Phase (Month $month of 2)';
  return 'Continuation Phase (Month $month of 6)';
}

List<_MedicationDisplay> _medicationItems(
    MedicationIntakePlan? plan, int days) {
  if (plan != null && plan.items.isNotEmpty) {
    return plan.items
        .map((item) => _MedicationDisplay(
              '${item.medicationName}${item.abbreviation == null ? '' : ' (${item.abbreviation})'}',
              item.dosageLabel.isEmpty ? 'Configured' : item.dosageLabel,
            ))
        .toList();
  }

  final month = ((days <= 0 ? 1 : days) / 30).ceil();
  if (month <= 2) {
    return const [
      _MedicationDisplay('Rifampicin (RIF)', '600mg'),
      _MedicationDisplay('Isoniazid (INH)', '300mg'),
      _MedicationDisplay('Pyrazinamide (PZA)', '1500mg'),
      _MedicationDisplay('Ethambutol (EMB)', '1200mg'),
    ];
  }

  return const [
    _MedicationDisplay('Rifampicin (RIF)', '600mg'),
    _MedicationDisplay('Isoniazid (INH)', '300mg'),
  ];
}

String? _formatTime(DateTime? time) {
  if (time == null) return null;
  return DateFormat('hh:mm a').format(time);
}

IconData _statusHistoryIcon(String status) {
  return switch (status) {
    'completed' => Icons.check_circle_outline_rounded,
    'defaulted' => Icons.person_off_outlined,
    'paused' => Icons.pause_circle_outline_rounded,
    'at_risk' => Icons.warning_amber_rounded,
    'on_treatment' || 'ongoing' => Icons.medication_liquid_rounded,
    _ => Icons.swap_horiz_rounded,
  };
}

String _statusHistoryTitle(TherapyStatusHistoryModel history) {
  final oldStatus =
      history.oldStatus == null ? null : _therapyStatus(history.oldStatus!);
  final newStatus = _therapyStatus(history.newStatus);
  if (oldStatus == null || oldStatus == newStatus) {
    return 'Status Updated: $newStatus';
  }
  return '$oldStatus -> $newStatus';
}

String _statusHistoryTime(TherapyStatusHistoryModel history) {
  return DateFormat('d MMM yyyy, HH:mm').format(history.changedAt);
}

String _statusHistoryBody(TherapyStatusHistoryModel history) {
  final notes = history.notes?.trim();
  if (notes == null || notes.isEmpty) {
    return 'No clinical notes were added for this status update.';
  }
  return notes;
}
