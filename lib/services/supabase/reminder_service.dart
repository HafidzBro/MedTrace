import 'package:medtrace/data/models/reminder_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class ReminderService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const ReminderService(this.context, this.patients);

  Future<ReminderModel> create({
    required String patientId,
    String? therapyId,
    String? therapyPhaseId,
    required String title,
    String? description,
    required String reminderType,
    required DateTime reminderTime,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('reminders')
        .insert({
          'patient_id': resolvedPatientId,
          'therapy_id': therapyId,
          'therapy_phase_id': therapyPhaseId,
          'title': title,
          'description': description,
          'reminder_type': reminderType,
          'reminder_time': context.timeToString(reminderTime),
          'status': 'pending',
        })
        .select()
        .single();

    return ReminderModel.fromJson(response);
  }

  Future<List<ReminderModel>> listForPatient(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('reminders')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('reminder_time', ascending: true);

    return (response as List)
        .map((row) => ReminderModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ReminderModel> ensureMedicationReminder({
    required String patientId,
    String? therapyId,
    String? therapyPhaseId,
    DateTime? reminderTime,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final existing = await context.client
        .from('reminders')
        .select()
        .eq('patient_id', resolvedPatientId)
        .eq('reminder_type', 'medication')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return ReminderModel.fromJson(existing);
    }

    return create(
      patientId: resolvedPatientId,
      therapyId: therapyId,
      therapyPhaseId: therapyPhaseId,
      title: 'Medication Reminder',
      description: 'Time to take your TB medication.',
      reminderType: 'medication',
      reminderTime: reminderTime ?? DateTime(0, 1, 1, 8),
    );
  }

  Future<ReminderModel> updateMedicationReminder({
    required String patientId,
    DateTime? reminderTime,
    bool? enabled,
  }) async {
    final reminder = await ensureMedicationReminder(patientId: patientId);
    return update(
      reminderId: reminder.id,
      reminderTime: reminderTime,
      status: enabled == null ? null : (enabled ? 'pending' : 'cancelled'),
    );
  }

  Future<ReminderModel> update({
    required String reminderId,
    String? title,
    String? description,
    DateTime? reminderTime,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (reminderTime != null) {
      data['reminder_time'] = context.timeToString(reminderTime);
    }
    if (status != null) data['status'] = status;

    final response = await context.client
        .from('reminders')
        .update(data)
        .eq('reminder_id', reminderId)
        .select()
        .single();

    return ReminderModel.fromJson(response);
  }

  Future<void> delete(String reminderId) {
    return context.client
        .from('reminders')
        .delete()
        .eq('reminder_id', reminderId);
  }
}
