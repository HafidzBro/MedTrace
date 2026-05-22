import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/data/models/models.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

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
    final treatmentState = ref.watch(patientTreatmentProvider(patientId));
    final logsState = ref.watch(patientMedicationLogsProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdherenceCard(logsState),
            const SizedBox(height: 16),
            _buildTreatmentCard(treatmentState),
            const SizedBox(height: 16),
            _buildRecentLogsCard(logsState),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(MedicationLogsState state) {
    final adherence = state.adherencePercentage;
    final color = adherence >= 80
        ? AppColors.success
        : adherence >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${adherence.toStringAsFixed(1)}%',
            style: AppTypography.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Treatment Adherence',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                'Taken',
                state.logs.where((l) => l.isTaken).length.toString(),
              ),
              _buildStat(
                'Missed',
                state.logs.where((l) => l.isMissed).length.toString(),
              ),
              _buildStat('Total', state.logs.length.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(label, style: AppTypography.caption.copyWith(color: Colors.white70)),
      ],
    );
  }

  Widget _buildTreatmentCard(TreatmentState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final treatment = state.treatment;
    if (treatment == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: const Text('No active treatment found'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Treatment Info',
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Phase', treatment.phase.toUpperCase()),
          _buildInfoRow('Status', treatment.status.toUpperCase()),
          _buildInfoRow('Start Date', _formatDate(treatment.startDate)),
          _buildInfoRow(
            'Days Elapsed',
            '${treatment.treatmentDaysElapsed} days',
          ),
          if (treatment.notes != null && treatment.notes!.isNotEmpty)
            _buildInfoRow('Notes', treatment.notes!),
        ],
      ),
    );
  }

  Widget _buildRecentLogsCard(MedicationLogsState state) {
    final recentLogs = state.logs.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Medication Logs',
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (recentLogs.isEmpty)
            Text(
              'No logs yet',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            )
          else
            ...recentLogs.map((log) => _buildLogItem(log)),
        ],
      ),
    );
  }

  Widget _buildLogItem(MedicationLogModel log) {
    final color = log.isTaken
        ? AppColors.success
        : log.isMissed
            ? AppColors.error
            : AppColors.warning;
    final icon = log.isTaken
        ? Icons.check_circle
        : log.isMissed
            ? Icons.cancel
            : Icons.schedule;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatDate(log.scheduledDate),
              style: AppTypography.bodySmall,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              log.status.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
