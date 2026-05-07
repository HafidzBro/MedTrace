import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/domain/entities/entities.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

/// Patient's daily medication schedule page
/// Shows all medications for the day with adherence tracking
class MedicationSchedulePage extends ConsumerStatefulWidget {
  const MedicationSchedulePage({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicationSchedulePage> createState() =>
      _MedicationSchedulePageState();
}

class _MedicationSchedulePageState
    extends ConsumerState<MedicationSchedulePage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medication Schedule')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final medicationLogsState = ref.watch(
      patientMedicationLogsProvider(userId),
    );
    final treatmentState = ref.watch(patientTreatmentProvider(userId));
    final medicationsState = ref.watch(
      treatmentMedicationsProvider(treatmentState.treatment?.id ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Schedule'),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientMedicationLogsProvider(userId));
          ref.invalidate(patientTreatmentProvider(userId));
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date selector
                _buildDateSelector(context),
                const SizedBox(height: 24),

                // Adherence summary
                _buildAdherenceSummary(medicationLogsState),
                const SizedBox(height: 24),

                // Medications list
                _buildMedicationsList(
                  context,
                  medicationsState,
                  medicationLogsState,
                  ref,
                  userId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.patient.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: Column(
              children: [
                Text(
                  _selectedDate.isToday
                      ? 'Today'
                      : _selectedDate.isTomorrow
                          ? 'Tomorrow'
                          : _selectedDate.isYesterday
                              ? 'Yesterday'
                              : '${_selectedDate.day} ${_getMonthName(_selectedDate.month)}',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.patient,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_selectedDate.dayOfWeekName, style: AppTypography.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceSummary(MedicationLogsState state) {
    final adherence = state.adherencePercentage;
    final color = adherence > 80
        ? AppColors.success
        : adherence > 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Circular progress indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: adherence / 100,
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    backgroundColor: color.withOpacity(0.2),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${adherence.toStringAsFixed(0)}%',
                      style: AppTypography.headlineMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adherence Rate',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (adherence > 80)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Great adherence! Keep it up',
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else if (adherence > 60)
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Try to take all medications',
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.error_rounded, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Take every medication on schedule',
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList(
    BuildContext context,
    MedicationsState medicationsState,
    MedicationLogsState logsState,
    WidgetRef ref,
    String userId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Medications',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (medicationsState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (medicationsState.medications.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.success.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medications today',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medicationsState.medications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final medication = medicationsState.medications[index];
              return _buildMedicationCard(
                context,
                medication,
                logsState,
                ref,
                userId,
              );
            },
          ),
      ],
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    Medication medication,
    MedicationLogsState logsState,
    WidgetRef ref,
    String userId,
  ) {
    // Find log for this medication today
    final todayLogs = logsState.logs.where(
      (log) =>
          log.medicationId == medication.id &&
          log.scheduledDate.isSameDate(_selectedDate),
    );
    final todayLog = todayLogs.isEmpty ? null : todayLogs.first;

    final isTaken = todayLog?.isTaken ?? false;
    final isMissed = todayLog?.isMissed ?? false;

    return GestureDetector(
      onTap: () {
        _showMedicationOptions(context, medication, todayLog, ref, userId);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isTaken
              ? AppColors.success.withOpacity(0.1)
              : isMissed
                  ? AppColors.error.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTaken
                ? AppColors.success.withOpacity(0.3)
                : isMissed
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.borderColor,
          ),
        ),
        child: Row(
          children: [
            // Medication icon/checkbox
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTaken
                    ? AppColors.success
                    : isMissed
                        ? AppColors.error
                        : AppColors.patient.withOpacity(0.2),
              ),
              child: Icon(
                isTaken
                    ? Icons.check
                    : isMissed
                        ? Icons.close
                        : Icons.medication,
                color: isTaken || isMissed ? Colors.white : AppColors.patient,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Medication details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isMissed ? AppColors.error : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.dosage} ${medication.unit}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication.frequency,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isTaken
                    ? AppColors.success.withOpacity(0.2)
                    : isMissed
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isTaken
                    ? 'Taken'
                    : isMissed
                        ? 'Missed'
                        : 'Pending',
                style: AppTypography.labelSmall.copyWith(
                  color: isTaken
                      ? AppColors.success
                      : isMissed
                          ? AppColors.error
                          : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicationOptions(
    BuildContext context,
    Medication medication,
    MedicationLog? log,
    WidgetRef ref,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              medication.name,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mark as taken
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(patientMedicationLogsProvider(userId).notifier)
                          .markMedicationTaken(medication.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marked as taken'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Mark as missed
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(patientMedicationLogsProvider(userId).notifier)
                          .markMedicationMissed(medication.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marked as missed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Missed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.borderColor,
                foregroundColor: AppColors.text,
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

extension _DateTimeX on DateTime {
  String get dayOfWeekName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}
