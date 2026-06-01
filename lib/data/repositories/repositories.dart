import 'package:medtrace/data/datasources/remote/supabase_remote_datasource.dart';
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

// Auth Repository
class AuthRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  AuthRepository({required this.remoteDataSource});

  Future<UserModel> registerPatient({
    required String email,
    required String password,
    required String doctorCode,
    required String fullName,
    DateTime? dateOfBirth,
    String? nik,
    DateTime? diagnosisDate,
    String? tbCaseCategory,
    String? tbCaseDescription,
    String? phoneNumber,
    String? gender,
    String? address,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
  }) async {
    return remoteDataSource.registerPatient(
      email: email,
      password: password,
      doctorCode: doctorCode,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      nik: nik,
      diagnosisDate: diagnosisDate,
      tbCaseCategory: tbCaseCategory,
      tbCaseDescription: tbCaseDescription,
      phoneNumber: phoneNumber,
      gender: gender,
      address: address,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: locationAccuracy,
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return remoteDataSource.login(email: email, password: password);
  }

  Future<void> logout() async {
    return remoteDataSource.logout();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final userId = remoteDataSource.getCurrentUserId();
      if (userId == null) return null;
      return remoteDataSource.getUser(userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    return remoteDataSource.resetPassword(email);
  }
}

// User Repository
class UserRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  UserRepository({required this.remoteDataSource});

  Future<UserModel> getUser(String userId) async {
    return remoteDataSource.getUser(userId);
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
    return remoteDataSource.updateProfile(
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

  Future<List<UserModel>> getPatients(String doctorId) async {
    return remoteDataSource.getMyPatients(doctorId);
  }

  Future<UserModel?> getDoctor(String patientId) async {
    return remoteDataSource.getMyDoctor(patientId);
  }
}

// Doctor Code Repository
class DoctorCodeRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  DoctorCodeRepository({required this.remoteDataSource});

  Future<String> generateCode({
    required String doctorId,
    int maxUses = 1,
    int expiryDays = 30,
  }) async {
    return remoteDataSource.generateDoctorCode(
      doctorId: doctorId,
      maxUses: maxUses,
      expiryDays: expiryDays,
    );
  }

  Future<DoctorCodeModel> validateCode(String code) async {
    return remoteDataSource.validateDoctorCode(code);
  }
}

// Treatment Repository
class TreatmentRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  TreatmentRepository({required this.remoteDataSource});

  Future<TreatmentModel> createTreatment({
    required String patientId,
    required String doctorId,
    required DateTime diagnosisDate,
    required DateTime startDate,
    String phase = 'intensive',
  }) async {
    return remoteDataSource.createTreatment(
      patientId: patientId,
      doctorId: doctorId,
      diagnosisDate: diagnosisDate,
      startDate: startDate,
      phase: phase,
    );
  }

  Future<TreatmentModel?> getPatientTreatment(String patientId) async {
    return remoteDataSource.getPatientTreatment(patientId);
  }

  Future<List<TreatmentModel>> getDoctorPatientsTreatments(
    String doctorId,
  ) async {
    return remoteDataSource.getDoctorPatientsTreatments(doctorId);
  }

  Future<TreatmentModel> updateTreatment({
    required String treatmentId,
    String? phase,
    String? status,
    double? adherencePercentage,
    String? notes,
  }) async {
    return remoteDataSource.updateTreatment(
      treatmentId: treatmentId,
      phase: phase,
      status: status,
      adherencePercentage: adherencePercentage,
      notes: notes,
    );
  }
}

// Medication Repository
class MedicationRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  MedicationRepository({required this.remoteDataSource});

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
    return remoteDataSource.createMedication(
      treatmentId: treatmentId,
      name: name,
      dosage: dosage,
      unit: unit,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      instructions: instructions,
    );
  }

  Future<List<MedicationModel>> getTreatmentMedications(
    String treatmentId,
  ) async {
    return remoteDataSource.getTreatmentMedications(treatmentId);
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
    return remoteDataSource.updateMedication(
      medicationId: medicationId,
      name: name,
      dosage: dosage,
      unit: unit,
      frequency: frequency,
      endDate: endDate,
      instructions: instructions,
    );
  }
}

// Medication Log Repository
class MedicationLogRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  MedicationLogRepository({required this.remoteDataSource});

  Future<MedicationLogModel> logMedication({
    required String medicationId,
    required String patientId,
    required DateTime scheduledDate,
    required String status,
    String? notes,
  }) async {
    return remoteDataSource.createMedicationLog(
      medicationId: medicationId,
      patientId: patientId,
      scheduledDate: scheduledDate,
      status: status,
      notes: notes,
    );
  }

  Future<List<MedicationLogModel>> getPatientMedicationLogs(
    String patientId,
  ) async {
    return remoteDataSource.getPatientMedicationLogs(patientId);
  }

  Future<List<MedicationLogModel>> getMedicationLogs(
    String medicationId,
  ) async {
    return remoteDataSource.getMedicationLogs(medicationId);
  }

  Future<MedicationLogModel> updateMedicationLog({
    required String logId,
    required String status,
    String? notes,
  }) async {
    return remoteDataSource.updateMedicationLog(
      logId: logId,
      status: status,
      notes: notes,
    );
  }
}

// Reminder Repository
class ReminderRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  ReminderRepository({required this.remoteDataSource});

  Future<ReminderModel> createReminder({
    required String patientId,
    required String title,
    String? description,
    required String reminderType,
    required DateTime scheduledDate,
    required DateTime scheduledTime,
  }) async {
    return remoteDataSource.createReminder(
      patientId: patientId,
      title: title,
      description: description,
      reminderType: reminderType,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
  }

  Future<List<ReminderModel>> getPatientReminders(String patientId) async {
    return remoteDataSource.getPatientReminders(patientId);
  }

  Future<ReminderModel> updateReminder({
    required String reminderId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    DateTime? scheduledTime,
  }) async {
    return remoteDataSource.updateReminder(
      reminderId: reminderId,
      title: title,
      description: description,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
  }

  Future<void> deleteReminder(String reminderId) async {
    return remoteDataSource.deleteReminder(reminderId);
  }
}

// Location Repository
class LocationRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  LocationRepository({required this.remoteDataSource});

  Future<PatientLocationModel> recordLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    String? address,
  }) async {
    return remoteDataSource.recordLocation(
      patientId: patientId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      address: address,
    );
  }

  Future<List<PatientLocationModel>> getPatientLocations(
    String patientId,
  ) async {
    return remoteDataSource.getPatientLocations(patientId);
  }

  Future<List<PatientLocationModel>> getAllPatientLocations(
    String doctorId,
  ) async {
    return remoteDataSource.getAllPatientLocations(doctorId);
  }
}

// Chatbot Repository
class ChatbotRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  ChatbotRepository({required this.remoteDataSource});

  Future<ChatbotConversation> createConversation(String patientId) async {
    return remoteDataSource.createChatbotConversation(patientId);
  }

  Future<List<ChatbotConversation>> getPatientConversations(
    String patientId,
  ) async {
    return remoteDataSource.getPatientConversations(patientId);
  }

  Future<ChatbotMessageModel> addMessage({
    required String conversationId,
    required String message,
    required String role,
  }) async {
    return remoteDataSource.addChatbotMessage(
      conversationId: conversationId,
      message: message,
      role: role,
    );
  }

  Future<List<ChatbotMessageModel>> getConversationMessages(
    String conversationId,
  ) async {
    return remoteDataSource.getChatbotMessages(conversationId);
  }
}

// Alert Repository
class AlertRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  AlertRepository({required this.remoteDataSource});

  Future<AlertModel> createAlert({
    required String doctorId,
    required String patientId,
    required String alertType,
    required String severity,
    required String title,
    String? description,
  }) async {
    return remoteDataSource.createAlert(
      doctorId: doctorId,
      patientId: patientId,
      alertType: alertType,
      severity: severity,
      title: title,
      description: description,
    );
  }

  Future<List<AlertModel>> getDoctorAlerts(String doctorId) async {
    return remoteDataSource.getDoctorAlerts(doctorId);
  }

  Future<AlertModel> updateAlert({
    required String alertId,
    bool? isRead,
    bool? actionTaken,
  }) async {
    return remoteDataSource.updateAlert(
      alertId: alertId,
      isRead: isRead,
      actionTaken: actionTaken,
    );
  }
}
