import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';
import 'package:intl/intl.dart';

class TreatmentDetailsPage extends ConsumerWidget {
  final String? patientId;

  const TreatmentDetailsPage({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPatientId = patientId ?? ref.watch(authProvider).user?.id;

    if (resolvedPatientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treatment Details')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final treatmentState = ref.watch(
      patientTreatmentProvider(resolvedPatientId),
    );
    final medicationLogsState = ref.watch(
      patientMedicationLogsProvider(resolvedPatientId),
    );

    if (treatmentState.isLoading || medicationLogsState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treatment Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final treatment = treatmentState.treatment;
    if (treatment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treatment Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: AppColors.lightGrey,
              ),
              const SizedBox(height: 16),
              Text('No active treatment', style: AppTypography.headline4),
            ],
          ),
        ),
      );
    }

    final adherence = medicationLogsState.adherencePercentage;
    final daysElapsed = treatment.treatmentDaysElapsed;

    return Scaffold(
      appBar: AppBar(title: const Text('Treatment Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Adherence Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Treatment Adherence', style: AppTypography.headline4),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${adherence.toStringAsFixed(1)}%',
                              style: AppTypography.headline2.copyWith(
                                color: adherence > 80
                                    ? AppColors.successGreen
                                    : adherence > 60
                                        ? AppColors.warningYellow
                                        : AppColors.errorRed,
                              ),
                            ),
                            Text(
                              'Adherence Rate',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: adherence / 100,
                                  backgroundColor: AppColors.lightGrey,
                                  valueColor: AlwaysStoppedAnimation(
                                    adherence > 80
                                        ? AppColors.successGreen
                                        : adherence > 60
                                            ? AppColors.warningYellow
                                            : AppColors.errorRed,
                                  ),
                                  strokeWidth: 8,
                                ),
                              ),
                              Text(
                                '${adherence.toStringAsFixed(0)}%',
                                style: AppTypography.headline4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Treatment Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treatment Information',
                      style: AppTypography.headline4,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Phase:', treatment.phase.toUpperCase()),
                    const SizedBox(height: 12),
                    _buildInfoRow('Status:', treatment.status.toUpperCase()),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Start Date:',
                      DateFormat('dd MMM yyyy').format(treatment.startDate),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Days Elapsed:', '$daysElapsed days'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Medications',
                    value: medicationLogsState.logs.length.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Taken',
                    value: medicationLogsState.logs
                        .where((log) => log.isTaken)
                        .length
                        .toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Missed',
                    value: medicationLogsState.logs
                        .where((log) => log.isMissed)
                        .length
                        .toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Adherence Trend (7 days)
            if (medicationLogsState.weeklyTrend.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('7-Day Trend', style: AppTypography.headline4),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: medicationLogsState.weeklyTrend
                              .map((v) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: _buildTrendBar(v),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('7 days ago', style: AppTypography.caption),
                          Text('Today', style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.mediumGrey),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTypography.headline3.copyWith(
                color: AppColors.patientPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.mediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBar(double value) {
    if (value < 0) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    final height = (value / 100) * 56 + 4;
    final color = value >= 80
        ? AppColors.successGreen
        : value >= 60
            ? AppColors.warningYellow
            : AppColors.errorRed;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
