import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final patientsState = ref.watch(doctorPatientsProvider(userId));
    final alertsState = ref.watch(doctorAlertsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), centerTitle: true, elevation: 0),
      body: patientsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(patientsState, alertsState),
                  const SizedBox(height: 24),
                  _buildAdherenceDistribution(patientsState),
                  const SizedBox(height: 24),
                  _buildAlertsBySeverity(alertsState),
                  const SizedBox(height: 24),
                  _buildPatientAdherenceList(patientsState),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(DoctorPatientsState patients, DoctorAlertsState alerts) {
    final totalPatients = patients.patients.length;
    final avgAdherence = totalPatients > 0
        ? patients.patients.fold<double>(0, (sum, p) => sum + p.adherencePercentage) / totalPatients
        : 0.0;
    final unresolvedAlerts = alerts.alerts.where((a) => !a.actionTaken).length;

    return Row(
      children: [
        Expanded(child: _buildCard('Patients', '$totalPatients', AppColors.doctor)),
        const SizedBox(width: 12),
        Expanded(child: _buildCard('Avg Adherence', '${avgAdherence.toStringAsFixed(0)}%',
            avgAdherence >= 80 ? AppColors.success : AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: _buildCard('Open Alerts', '$unresolvedAlerts', AppColors.error)),
      ],
    );
  }

  Widget _buildCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildAdherenceDistribution(DoctorPatientsState state) {
    final good = state.patients.where((p) => p.adherencePercentage >= 80).length;
    final warning = state.patients.where((p) => p.adherencePercentage >= 60 && p.adherencePercentage < 80).length;
    final critical = state.patients.where((p) => p.adherencePercentage < 60).length;
    final total = state.patients.length;

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
          Text('Adherence Distribution', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (total > 0) ...[
            _buildDistributionBar(good, warning, critical, total),
            const SizedBox(height: 12),
          ],
          _buildLegendRow(AppColors.success, 'Good (>=80%)', good),
          const SizedBox(height: 8),
          _buildLegendRow(AppColors.warning, 'At Risk (60-80%)', warning),
          const SizedBox(height: 8),
          _buildLegendRow(AppColors.error, 'Critical (<60%)', critical),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(int good, int warning, int critical, int total) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            if (good > 0) Expanded(flex: good, child: Container(color: AppColors.success)),
            if (warning > 0) Expanded(flex: warning, child: Container(color: AppColors.warning)),
            if (critical > 0) Expanded(flex: critical, child: Container(color: AppColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, int count) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTypography.bodySmall)),
        Text('$count', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAlertsBySeverity(DoctorAlertsState state) {
    final critical = state.alerts.where((a) => a.severity == 'critical').length;
    final high = state.alerts.where((a) => a.severity == 'high').length;
    final medium = state.alerts.where((a) => a.severity == 'medium').length;
    final low = state.alerts.where((a) => a.severity == 'low').length;
    final maxVal = [critical, high, medium, low].fold<int>(1, (a, b) => b > a ? b : a);

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
          Text('Alerts by Severity', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildBarRow('Critical', critical, maxVal, AppColors.error),
          const SizedBox(height: 8),
          _buildBarRow('High', high, maxVal, AppColors.warning),
          const SizedBox(height: 8),
          _buildBarRow('Medium', medium, maxVal, const Color(0xFFFBBF24)),
          const SizedBox(height: 8),
          _buildBarRow('Low', low, maxVal, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildBarRow(String label, int value, int max, Color color) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: AppTypography.caption)),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: max > 0 ? value / max : 0,
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 24, child: Text('$value', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildPatientAdherenceList(DoctorPatientsState state) {
    final sorted = [...state.patients]..sort((a, b) => a.adherencePercentage.compareTo(b.adherencePercentage));

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
          Text('Patient Adherence Ranking', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...sorted.take(10).map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(p.patient.fullName ?? p.patient.email, style: AppTypography.bodySmall)),
                    Text(
                      '${p.adherencePercentage.toStringAsFixed(0)}%',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: p.adherencePercentage >= 80
                            ? AppColors.success
                            : p.adherencePercentage >= 60
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
