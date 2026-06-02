import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class MedicationLogService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const MedicationLogService(this.context, this.patients);

  Future<MedicationLogModel> create({
    required String patientId,
    required String therapyId,
    String? therapyPhaseId,
    required DateTime scheduledAt,
    String status = 'pending',
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('medication_logs')
        .insert({
          'patient_id': resolvedPatientId,
          'therapy_id': therapyId,
          'therapy_phase_id': therapyPhaseId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'taken_at':
              status == 'taken' ? DateTime.now().toIso8601String() : null,
          'status': status,
        })
        .select()
        .single();

    return MedicationLogModel.fromJson(response);
  }

  Future<List<MedicationLogModel>> listForPatient(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('scheduled_at', ascending: false);

    return (response as List)
        .map((row) => MedicationLogModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicationLogModel>> listForPatients(
    List<String> patientIds,
  ) async {
    if (patientIds.isEmpty) return [];

    final response = await context.client
        .from('medication_logs')
        .select()
        .filter('patient_id', 'in', '(${patientIds.join(',')})')
        .order('scheduled_at', ascending: false);

    return (response as List)
        .map((row) => MedicationLogModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicationLogModel>> listForPatientBetween({
    required String patientId,
    required DateTime start,
    required DateTime end,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('patient_id', resolvedPatientId)
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((row) => MedicationLogModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicationLogModel>> listForTherapy(String therapyId) async {
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('therapy_id', therapyId)
        .order('scheduled_at', ascending: false);

    return (response as List)
        .map((row) => MedicationLogModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MedicationLogModel> updateStatus({
    required String medicationLogId,
    required String status,
  }) async {
    final response = await context.client
        .from('medication_logs')
        .update({
          'status': status,
          'taken_at':
              status == 'taken' ? DateTime.now().toIso8601String() : null,
        })
        .eq('medication_log_id', medicationLogId)
        .select()
        .single();

    return MedicationLogModel.fromJson(response);
  }

  Future<List<MedicationLogModel>> ensureWeeklyLogs({
    required String patientId,
    required TreatmentModel therapy,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final now = DateTime.now();
    final today = _dateOnly(now);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final firstScheduledDay = _dateOnly(therapy.startDate).isAfter(weekStart)
        ? _dateOnly(therapy.startDate)
        : weekStart;
    final schedule = await _currentPhaseSchedule(therapy);
    final reminderTime = await _medicationReminderTime(resolvedPatientId);
    final scheduleTime = reminderTime ?? schedule.time;

    for (var day = firstScheduledDay;
        day.isBefore(weekEnd);
        day = day.add(const Duration(days: 1))) {
      final scheduledAt = DateTime(
        day.year,
        day.month,
        day.day,
        scheduleTime.hour,
        scheduleTime.minute,
      );
      final existing = await _logForTherapyOnDay(
        therapyId: therapy.id,
        day: day,
      );

      if (existing == null) {
        await create(
          patientId: resolvedPatientId,
          therapyId: therapy.id,
          therapyPhaseId: schedule.therapyPhaseId,
          scheduledAt: scheduledAt,
          status: day.isBefore(today) ? 'missed' : 'pending',
        );
      } else if (day.isBefore(today) && existing.isPending) {
        await updateStatus(
          medicationLogId: existing.id,
          status: 'missed',
        );
      }
    }

    return listForPatientBetween(
      patientId: resolvedPatientId,
      start: weekStart,
      end: weekEnd,
    );
  }

  Future<MedicationLogModel> logTodayDose(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('patient_id', resolvedPatientId)
        .eq('status', 'pending')
        .gte('scheduled_at', today.toIso8601String())
        .lt('scheduled_at', tomorrow.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return updateStatus(
        medicationLogId: response['medication_log_id'] as String,
        status: 'taken',
      );
    }

    final fallback = await context.client
        .from('medication_logs')
        .select()
        .eq('patient_id', resolvedPatientId)
        .gte('scheduled_at', today.toIso8601String())
        .lt('scheduled_at', tomorrow.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (fallback != null) {
      return MedicationLogModel.fromJson(fallback);
    }

    throw StateError('No medication schedule is available for today.');
  }

  Future<MedicationLogModel?> todayLog(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('patient_id', resolvedPatientId)
        .gte('scheduled_at', today.toIso8601String())
        .lt('scheduled_at', tomorrow.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return MedicationLogModel.fromJson(response);
  }

  Future<void> reschedulePendingLogsForReminderTime({
    required String patientId,
    required DateTime reminderTime,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final today = _dateOnly(DateTime.now());
    final response = await context.client
        .from('medication_logs')
        .select('medication_log_id, scheduled_at')
        .eq('patient_id', resolvedPatientId)
        .eq('status', 'pending')
        .gte('scheduled_at', today.toIso8601String())
        .order('scheduled_at', ascending: true);

    final logs =
        (response as List).map((row) => row as Map<String, dynamic>).toList();

    for (final log in logs) {
      final scheduledAt = DateTime.tryParse(log['scheduled_at'].toString());
      final medicationLogId = log['medication_log_id'] as String?;
      if (scheduledAt == null || medicationLogId == null) continue;

      final updatedSchedule = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      await context.client
          .from('medication_logs')
          .update({'scheduled_at': updatedSchedule.toIso8601String()}).eq(
              'medication_log_id', medicationLogId);
    }
  }

  Future<_PhaseSchedule> _currentPhaseSchedule(TreatmentModel therapy) async {
    final response = await context.client
        .from('therapy_phases')
        .select(
          'therapy_phase_id, intake_time, start_date, end_date, start_month, end_month, status',
        )
        .eq('therapy_id', therapy.id)
        .order('phase_order', ascending: true);

    final phases =
        (response as List).map((row) => row as Map<String, dynamic>).toList();
    if (phases.isEmpty) return const _PhaseSchedule();

    final phase = _currentPhaseForTherapy(therapy, phases);
    return _PhaseSchedule(
      therapyPhaseId: phase['therapy_phase_id'] as String?,
      time: _parseTime(phase['intake_time'] as String?),
    );
  }

  Future<_ClockTime?> _medicationReminderTime(String patientId) async {
    final response = await context.client
        .from('reminders')
        .select('reminder_time')
        .eq('patient_id', patientId)
        .eq('reminder_type', 'medication')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final reminderTime = response?['reminder_time'] as String?;
    if (reminderTime == null) return null;
    return _parseTime(reminderTime);
  }

  Map<String, dynamic> _currentPhaseForTherapy(
    TreatmentModel therapy,
    List<Map<String, dynamic>> phases,
  ) {
    final now = DateTime.now();
    final monthOnTherapy = (now.difference(therapy.startDate).inDays ~/ 30) + 1;

    for (final phase in phases) {
      final startDate = _parseNullableDate(phase['start_date']);
      final endDate = _parseNullableDate(phase['end_date']);
      if (startDate != null &&
          endDate != null &&
          !now.isBefore(startDate) &&
          now.isBefore(endDate.add(const Duration(days: 1)))) {
        return phase;
      }
    }

    for (final phase in phases) {
      final startMonth = phase['start_month'] as int?;
      final endMonth = phase['end_month'] as int?;
      if (startMonth != null &&
          endMonth != null &&
          monthOnTherapy >= startMonth &&
          monthOnTherapy <= endMonth) {
        return phase;
      }
    }

    return phases.firstWhere(
      (phase) => phase['status'] == 'active',
      orElse: () => phases.first,
    );
  }

  Future<MedicationLogModel?> _logForTherapyOnDay({
    required String therapyId,
    required DateTime day,
  }) async {
    final start = _dateOnly(day);
    final end = start.add(const Duration(days: 1));
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('therapy_id', therapyId)
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return MedicationLogModel.fromJson(response);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  _ClockTime _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const _ClockTime(hour: 8, minute: 0);
    }

    final parts = value.split(':');
    return _ClockTime(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 8,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );
  }
}

class _PhaseSchedule {
  final String? therapyPhaseId;
  final _ClockTime time;

  const _PhaseSchedule({
    this.therapyPhaseId,
    this.time = const _ClockTime(hour: 8, minute: 0),
  });

  int get hour => time.hour;
  int get minute => time.minute;
}

class _ClockTime {
  final int hour;
  final int minute;

  const _ClockTime({
    required this.hour,
    required this.minute,
  });
}
