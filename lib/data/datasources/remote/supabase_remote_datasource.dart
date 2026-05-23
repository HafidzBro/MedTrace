import 'package:logger/logger.dart';
import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/models.dart';
import 'package:medtrace/domain/entities/entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRemoteDataSource {
  final SupabaseClient client;
  final Logger logger = Logger();

  SupabaseRemoteDataSource({required this.client});

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
  }) async {
    try {
      final normalizedDoctorCode = doctorCode.toUpperCase();

      // Validate doctor code
      final codeResponse = await client
          .from('doctor_codes')
          .select()
          .eq('code', normalizedDoctorCode)
          .maybeSingle();

      if (codeResponse == null) {
        throw InvalidDoctorCodeException(message: 'Invalid doctor code');
      }

      final code = DoctorCodeModel.fromJson(codeResponse);
      if (!code.canBeUsed) {
        throw InvalidDoctorCodeException(
          message: 'Doctor code has expired or reached maximum uses',
        );
      }

      if (client.auth.currentUser != null) {
        await client.auth.signOut();
      }

      // Register user
      final authResponse = await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (authResponse.user == null) {
        throw AuthenticationException(message: 'Registration failed');
      }

      final userId = authResponse.user!.id;

      if (authResponse.session == null || client.auth.currentUser?.id != userId) {
        throw AuthenticationException(
          message:
              'Registration created an auth user, but no active patient session was returned. Disable email confirmation in Supabase Auth for this flow, or complete patient registration after email verification.',
        );
      }

      final profile = await client.rpc(
        'complete_patient_registration',
        params: {
          'p_user_id': userId,
          'p_email': email.trim().toLowerCase(),
          'p_full_name': fullName,
          'p_doctor_code': code.code.toUpperCase(),
        },
      ).single();

      return UserModel.fromJson(profile);
    } on AppException {
      rethrow;
    } catch (e) {
      logger.e('Registration error', error: e);
      throw UnknownException(message: 'Registration failed: $e');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthenticationException(message: 'Invalid email or password');
      }

      return getUser(response.user!.id);
    } catch (e) {
      logger.e('Login error', error: e);
      throw AuthenticationException(message: 'Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      logger.e('Logout error', error: e);
      throw UnknownException(message: 'Logout failed');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      logger.e('Password reset error', error: e);
      throw UnknownException(message: 'Password reset failed');
    }
  }

  // ============================================================
  // USER METHODS
  // ============================================================

  Future<UserModel> getUser(String userId) async {
    try {
      final response =
          await client.from('profiles').select().eq('id', userId).single();
      return UserModel.fromJson(response);
    } catch (e) {
      logger.e('Get user error', error: e);
      throw NotFoundException(message: 'User not found');
    }
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? country,
    String? city,
    String? gender,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (bio != null) data['bio'] = bio;
      if (country != null) data['country'] = country;
      if (city != null) data['city'] = city;
      if (gender != null) data['gender'] = gender;

      await client.from('profiles').update(data).eq('id', userId);
      return getUser(userId);
    } catch (e) {
      logger.e('Update profile error', error: e);
      throw DatabaseException(message: 'Failed to update profile');
    }
  }

  // ============================================================
  // DOCTOR/PATIENT RELATIONSHIP
  // ============================================================

  Future<List<UserModel>> getMyPatients(String doctorId) async {
    try {
      final response = await client
          .from('doctor_patients')
          .select('patient_id')
          .eq('doctor_id', doctorId);

      final patientIds =
          (response as List).map((e) => e['patient_id'] as String).toList();

      if (patientIds.isEmpty) return [];

      final patients = await client
          .from('profiles')
          .select()
          .filter('id', 'in', '(${patientIds.join(',')})');

      return (patients as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      logger.e('Get my patients error', error: e);
      return [];
    }
  }

  Future<UserModel?> getMyDoctor(String patientId) async {
    try {
      final response = await client
          .from('doctor_patients')
          .select('doctor_id')
          .eq('patient_id', patientId)
          .maybeSingle();

      if (response == null) return null;

      final doctor = await client
          .from('profiles')
          .select()
          .eq('id', response['doctor_id'])
          .single();

      return UserModel.fromJson(doctor);
    } catch (e) {
      logger.e('Get my doctor error', error: e);
      return null;
    }
  }

  // ============================================================
  // DOCTOR CODE METHODS
  // ============================================================

  Future<String> generateDoctorCode({
    required String doctorId,
    int maxUses = 1,
    int expiryDays = 30,
  }) async {
    try {
      final code = _generateRandomCode();
      final expiresAt = DateTime.now().add(Duration(days: expiryDays));

      await client.from('doctor_codes').insert({
        'doctor_id': doctorId,
        'code': code,
        'max_uses': maxUses,
        'expires_at': expiresAt.toIso8601String(),
      });

      return code;
    } catch (e) {
      logger.e('Generate doctor code error', error: e);
      throw DatabaseException(message: 'Failed to generate doctor code');
    }
  }

  Future<DoctorCodeModel> validateDoctorCode(String code) async {
    try {
      final response = await client
          .from('doctor_codes')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (response == null) {
        throw InvalidDoctorCodeException(
          message: 'Invalid or expired doctor code',
        );
      }

      return DoctorCodeModel.fromJson(response);
    } catch (e) {
      logger.e('Validate doctor code error', error: e);
      throw InvalidDoctorCodeException(
        message: 'Invalid or expired doctor code',
      );
    }
  }

  // ============================================================
  // TREATMENT METHODS
  // ============================================================

  Future<TreatmentModel> createTreatment({
    required String patientId,
    required String doctorId,
    required DateTime diagnosisDate,
    required DateTime startDate,
    String phase = 'intensive',
  }) async {
    try {
      final response = await client
          .from('treatments')
          .insert({
            'patient_id': patientId,
            'doctor_id': doctorId,
            'diagnosis_date': diagnosisDate.toIso8601String(),
            'start_date': startDate.toIso8601String(),
            'phase': phase,
            'status': 'ongoing',
            'adherence_percentage': 0.0,
          })
          .select()
          .single();

      return TreatmentModel.fromJson(response);
    } catch (e) {
      logger.e('Create treatment error', error: e);
      throw DatabaseException(message: 'Failed to create treatment');
    }
  }

  Future<TreatmentModel?> getPatientTreatment(String patientId) async {
    try {
      final response = await client
          .from('treatments')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'ongoing')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return TreatmentModel.fromJson(response);
    } catch (e) {
      logger.e('Get patient treatment error', error: e);
      return null;
    }
  }

  Future<List<TreatmentModel>> getDoctorPatientsTreatments(
    String doctorId,
  ) async {
    try {
      final response = await client
          .from('treatments')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => TreatmentModel.fromJson(e)).toList();
    } catch (e) {
      logger.e('Get doctor patients treatments error', error: e);
      return [];
    }
  }

  Future<TreatmentModel> updateTreatment({
    required String treatmentId,
    String? phase,
    String? status,
    double? adherencePercentage,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (phase != null) data['phase'] = phase;
      if (status != null) data['status'] = status;
      if (adherencePercentage != null)
        data['adherence_percentage'] = adherencePercentage;
      if (notes != null) data['notes'] = notes;

      final response = await client
          .from('treatments')
          .update(data)
          .eq('id', treatmentId)
          .select()
          .single();

      return TreatmentModel.fromJson(response);
    } catch (e) {
      logger.e('Update treatment error', error: e);
      throw DatabaseException(message: 'Failed to update treatment');
    }
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
      if (scheduledTime != null)
        data['scheduled_time'] =
            '${scheduledTime.hour}:${scheduledTime.minute}';

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

      final data = response as Map<String, dynamic>;
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

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecond;
    String code = '';
    for (var i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }
    return code;
  }
}
