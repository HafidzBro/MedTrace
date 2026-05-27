import 'package:logger/logger.dart';
import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/alert_model.dart';
import 'package:medtrace/data/models/chatbot_conversation_model.dart';
import 'package:medtrace/data/models/chatbot_message_model.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/medication_model.dart';
import 'package:medtrace/data/models/patient_location_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/data/models/reminder_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
import 'package:medtrace/services/supabase/auth_service.dart';
import 'package:medtrace/services/supabase/doctor_code_service.dart';
import 'package:medtrace/services/supabase/doctor_service.dart';
import 'package:medtrace/services/supabase/profile_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';
import 'package:medtrace/services/supabase/therapy_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRemoteDataSource {
  final SupabaseClient client;
  final Logger logger = Logger();
  late final SupabaseServiceContext serviceContext;
  late final ProfileService profiles;
  late final DoctorService doctors;
  late final DoctorCodeService doctorCodes;
  late final AuthService auth;
  late final TherapyService therapies;

  SupabaseRemoteDataSource({required this.client}) {
    serviceContext = SupabaseServiceContext(client: client, logger: logger);
    profiles = ProfileService(serviceContext);
    doctors = DoctorService(serviceContext, profiles);
    doctorCodes = DoctorCodeService(serviceContext, doctors);
    auth = AuthService(serviceContext, profiles, doctorCodes);
    therapies = TherapyService(serviceContext, doctors);
  }

  // ============================================================
  // AUTH METHODS
  // ============================================================

  String? getCurrentUserId() {
    return client.auth.currentUser?.id;
  }

  Future<UserModel> registerPatient({
    required String email,
    required String password,
    required String doctorCode,
    required String fullName,
  }) {
    return auth.registerPatient(
      email: email,
      password: password,
      doctorCode: doctorCode,
      fullName: fullName,
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) {
    return auth.loginUser(email: email, password: password);
  }

  Future<void> logout() => auth.logout();

  Future<void> resetPassword(String email) => auth.resetPassword(email);

  // ============================================================
  // USER METHODS
  // ============================================================

  Future<UserModel> getUser(String userId) => profiles.getByAuthUserId(userId);

  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? country,
    String? city,
    String? gender,
  }) {
    return profiles.updateProfile(
      userId: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      bio: bio,
      country: country,
      city: city,
      gender: gender,
    );
  }

  // ============================================================
  // DOCTOR/PATIENT RELATIONSHIP
  // ============================================================

  Future<List<UserModel>> getMyPatients(String doctorId) =>
      doctors.getPatients(doctorId);

  Future<UserModel?> getMyDoctor(String patientId) =>
      doctors.getDoctorForPatient(patientId);

  // ============================================================
  // DOCTOR CODE METHODS
  // ============================================================

  Future<String> generateDoctorCode({
    required String doctorId,
    int maxUses = 1,
    int expiryDays = 30,
  }) {
    return doctorCodes.generate(
      doctorId: doctorId,
      maxUses: maxUses,
      expiryDays: expiryDays,
    );
  }

  Future<DoctorCodeModel> validateDoctorCode(String code) =>
      doctorCodes.validate(code);

  // ============================================================
  // TREATMENT METHODS
  // ============================================================

  Future<TreatmentModel> createTreatment({
    required String patientId,
    required String doctorId,
    required DateTime diagnosisDate,
    required DateTime startDate,
    String phase = 'intensive',
  }) {
    return therapies.createTreatment(
      patientId: patientId,
      doctorId: doctorId,
      diagnosisDate: diagnosisDate,
      startDate: startDate,
      phase: phase,
    );
  }

  Future<TreatmentModel?> getPatientTreatment(String patientId) =>
      therapies.getPatientTreatment(patientId);

  Future<List<TreatmentModel>> getDoctorPatientsTreatments(
    String doctorId,
  ) =>
      therapies.getDoctorPatientsTreatments(doctorId);

  Future<TreatmentModel> updateTreatment({
    required String treatmentId,
    String? phase,
    String? status,
    double? adherencePercentage,
    String? notes,
  }) {
    return therapies.updateTreatment(
      treatmentId: treatmentId,
      phase: phase,
      status: status,
      adherencePercentage: adherencePercentage,
      notes: notes,
    );
  }

  // ============================================================
  // MEDICATION METHODS
  // ============================================================

  Future<MedicationModel> createMedication({
    required String treatmentId,
    required String name,
    required String dosage,
    required String unit,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? instructions,
  }) async {
    try {
      final response = await client
          .from('medications')
          .insert({
            'treatment_id': treatmentId,
            'name': name,
            'dosage': dosage,
            'unit': unit,
            'frequency': frequency,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'instructions': instructions,
          })
          .select()
          .single();

      return MedicationModel.fromJson(response);
    } catch (e) {
      logger.e('Create medication error', error: e);
      throw DatabaseException(message: 'Failed to create medication');
    }
  }

  Future<List<MedicationModel>> getTreatmentMedications(
    String treatmentId,
  ) async {
    try {
      final response = await client
          .from('medications')
          .select()
          .eq('treatment_id', treatmentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => MedicationModel.fromJson(e))
          .toList();
    } catch (e) {
      logger.e('Get treatment medications error', error: e);
      return [];
    }
  }

  Future<MedicationModel> updateMedication({
    required String medicationId,
    String? name,
    String? dosage,
    String? unit,
    String? frequency,
    DateTime? endDate,
    String? instructions,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (dosage != null) data['dosage'] = dosage;
      if (unit != null) data['unit'] = unit;
      if (frequency != null) data['frequency'] = frequency;
      if (endDate != null) data['end_date'] = endDate.toIso8601String();
      if (instructions != null) data['instructions'] = instructions;

      final response = await client
          .from('medications')
          .update(data)
          .eq('id', medicationId)
          .select()
          .single();

      return MedicationModel.fromJson(response);
    } catch (e) {
      logger.e('Update medication error', error: e);
      throw DatabaseException(message: 'Failed to update medication');
    }
  }

  // ============================================================
  // MEDICATION LOG METHODS
  // ============================================================

  Future<MedicationLogModel> createMedicationLog({
    required String medicationId,
    required String patientId,
    required DateTime scheduledDate,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await client
          .from('medication_logs')
          .insert({
            'medication_id': medicationId,
            'patient_id': patientId,
            'scheduled_date': scheduledDate.toIso8601String(),
            'scheduled_time': '${DateTime.now().hour}:${DateTime.now().minute}',
            'status': status,
            'notes': notes,
            'taken_at':
                status == 'taken' ? DateTime.now().toIso8601String() : null,
          })
          .select()
          .single();

      return MedicationLogModel.fromJson(response);
    } catch (e) {
      logger.e('Create medication log error', error: e);
      throw DatabaseException(message: 'Failed to create medication log');
    }
  }

  Future<List<MedicationLogModel>> getPatientMedicationLogs(
    String patientId,
  ) async {
    try {
      final response = await client
          .from('medication_logs')
          .select()
          .eq('patient_id', patientId)
          .order('scheduled_date', ascending: false);

      return (response as List)
          .map((e) => MedicationLogModel.fromJson(e))
          .toList();
    } catch (e) {
      logger.e('Get patient medication logs error', error: e);
      return [];
    }
  }

  Future<List<MedicationLogModel>> getMedicationLogs(
    String medicationId,
  ) async {
    try {
      final response = await client
          .from('medication_logs')
          .select()
          .eq('medication_id', medicationId)
          .order('scheduled_date', ascending: false);

      return (response as List)
          .map((e) => MedicationLogModel.fromJson(e))
          .toList();
    } catch (e) {
      logger.e('Get medication logs error', error: e);
      return [];
    }
  }

  Future<MedicationLogModel> updateMedicationLog({
    required String logId,
    required String status,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (notes != null) data['notes'] = notes;
      if (status == 'taken') {
        data['taken_at'] = DateTime.now().toIso8601String();
      }

      final response = await client
          .from('medication_logs')
          .update(data)
          .eq('id', logId)
          .select()
          .single();

      return MedicationLogModel.fromJson(response);
    } catch (e) {
      logger.e('Update medication log error', error: e);
      throw DatabaseException(message: 'Failed to update medication log');
    }
  }

  // ============================================================
  // REMINDER METHODS
  // ============================================================

  Future<ReminderModel> createReminder({
    required String patientId,
    required String title,
    String? description,
    required String reminderType,
    required DateTime scheduledDate,
    required DateTime scheduledTime,
  }) async {
    try {
      final response = await client
          .from('reminders')
          .insert({
            'patient_id': patientId,
            'title': title,
            'description': description,
            'reminder_type': reminderType,
            'scheduled_date': scheduledDate.toIso8601String(),
            'scheduled_time': '${scheduledTime.hour}:${scheduledTime.minute}',
          })
          .select()
          .single();

      return ReminderModel.fromJson(response);
    } catch (e) {
      logger.e('Create reminder error', error: e);
      throw DatabaseException(message: 'Failed to create reminder');
    }
  }

  Future<List<ReminderModel>> getPatientReminders(String patientId) async {
    try {
      final response = await client
          .from('reminders')
          .select()
          .eq('patient_id', patientId)
          .order('scheduled_date', ascending: true);

      return (response as List).map((e) => ReminderModel.fromJson(e)).toList();
    } catch (e) {
      logger.e('Get patient reminders error', error: e);
      return [];
    }
  }

  Future<ReminderModel> updateReminder({
    required String reminderId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    DateTime? scheduledTime,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (scheduledDate != null) data['scheduled_date'] = scheduledDate;
      if (scheduledTime != null) {
        data['scheduled_time'] =
            '${scheduledTime.hour}:${scheduledTime.minute}';
      }

      final response = await client
          .from('reminders')
          .update(data)
          .eq('id', reminderId)
          .select()
          .single();

      return ReminderModel.fromJson(response);
    } catch (e) {
      logger.e('Update reminder error', error: e);
      throw DatabaseException(message: 'Failed to update reminder');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await client.from('reminders').delete().eq('id', reminderId);
    } catch (e) {
      logger.e('Delete reminder error', error: e);
      throw DatabaseException(message: 'Failed to delete reminder');
    }
  }

  // ============================================================
  // LOCATION METHODS
  // ============================================================

  Future<PatientLocationModel> recordLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    String? address,
  }) async {
    try {
      final response = await client
          .from('patient_locations')
          .insert({
            'patient_id': patientId,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'altitude': altitude,
            'address': address,
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return PatientLocationModel.fromJson(response);
    } catch (e) {
      logger.e('Record location error', error: e);
      throw DatabaseException(message: 'Failed to record location');
    }
  }

  Future<List<PatientLocationModel>> getPatientLocations(
    String patientId,
  ) async {
    try {
      final response = await client
          .from('patient_locations')
          .select()
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((e) => PatientLocationModel.fromJson(e))
          .toList();
    } catch (e) {
      logger.e('Get patient locations error', error: e);
      return [];
    }
  }

  Future<List<PatientLocationModel>> getAllPatientLocations(
    String doctorId,
  ) async {
    try {
      // Get all patients for this doctor
      final patients = await getMyPatients(doctorId);
      final patientIds = patients.map((p) => p.id).toList();

      if (patientIds.isEmpty) return [];

      final response = await client
          .from('patient_locations')
          .select()
          .filter('patient_id', 'in', '(${patientIds.join(',')})')
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((e) => PatientLocationModel.fromJson(e))
          .toList();
    } catch (e) {
      logger.e('Get all patient locations error', error: e);
      return [];
    }
  }

  // ============================================================
  // CHATBOT METHODS
  // ============================================================

  Future<ChatbotConversation> createChatbotConversation(
    String patientId,
  ) async {
    try {
      final response = await client
          .from('chatbot_conversations')
          .insert({
            'patient_id': patientId,
            'title': 'Conversation ${DateTime.now().toIso8601String()}',
          })
          .select()
          .single();

      final data = response;
      return ChatbotConversation(
        id: data['id'] ?? '',
        patientId: data['patient_id'] ?? '',
        title: data['title'],
        createdAt: DateTime.parse(
          data['created_at'] ?? DateTime.now().toString(),
        ),
        updatedAt: DateTime.parse(
          data['updated_at'] ?? DateTime.now().toString(),
        ),
      );
    } catch (e) {
      logger.e('Create conversation error', error: e);
      throw DatabaseException(message: 'Failed to create conversation');
    }
  }

  Future<List<ChatbotConversation>> getPatientConversations(
    String patientId,
  ) async {
    try {
      final response = await client
          .from('chatbot_conversations')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        final data = e as Map<String, dynamic>;
        return ChatbotConversation(
          id: data['id'] ?? '',
          patientId: data['patient_id'] ?? '',
          title: data['title'],
          createdAt: DateTime.parse(
            data['created_at'] ?? DateTime.now().toString(),
          ),
          updatedAt: DateTime.parse(
            data['updated_at'] ?? DateTime.now().toString(),
          ),
        );
      }).toList();
    } catch (e) {
      logger.e('Get conversations error', error: e);
      return [];
    }
  }

  Future<ChatbotMessageModel> addChatbotMessage({
    required String conversationId,
    required String message,
    required String role,
  }) async {
    try {
      final response = await client
          .from('chatbot_messages')
          .insert({
            'conversation_id': conversationId,
            'message': message,
            'role': role,
          })
          .select()
          .single();

      return ChatbotMessageModel.fromJson(response);
    } catch (e) {
      logger.e('Add message error', error: e);
      throw DatabaseException(message: 'Failed to add message');
    }
  }

  Future<List<ChatbotMessageModel>> getChatbotMessages(
    String conversationId,
  ) async {
    try {
      final response = await client
          .from('chatbot_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((e) => ChatbotMessageModel.fromJson(e))
          .toList();
    } catch (e) {
      logger.e('Get messages error', error: e);
      return [];
    }
  }

  // ============================================================
  // ALERT METHODS
  // ============================================================

  Future<AlertModel> createAlert({
    required String doctorId,
    required String patientId,
    required String alertType,
    required String severity,
    required String title,
    String? description,
  }) async {
    try {
      final response = await client
          .from('alerts')
          .insert({
            'doctor_id': doctorId,
            'patient_id': patientId,
            'alert_type': alertType,
            'severity': severity,
            'title': title,
            'description': description,
          })
          .select()
          .single();

      return AlertModel.fromJson(response);
    } catch (e) {
      logger.e('Create alert error', error: e);
      throw DatabaseException(message: 'Failed to create alert');
    }
  }

  Future<List<AlertModel>> getDoctorAlerts(String doctorId) async {
    try {
      final response = await client
          .from('alerts')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => AlertModel.fromJson(e)).toList();
    } catch (e) {
      logger.e('Get alerts error', error: e);
      return [];
    }
  }

  Future<AlertModel> updateAlert({
    required String alertId,
    bool? isRead,
    bool? actionTaken,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (isRead != null) {
        data['is_read'] = isRead;
        if (isRead) data['read_at'] = DateTime.now().toIso8601String();
      }
      if (actionTaken != null) data['action_taken'] = actionTaken;

      final response = await client
          .from('alerts')
          .update(data)
          .eq('id', alertId)
          .select()
          .single();

      return AlertModel.fromJson(response);
    } catch (e) {
      logger.e('Update alert error', error: e);
      throw DatabaseException(message: 'Failed to update alert');
    }
  }
}
