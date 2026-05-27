import 'package:logger/logger.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
import 'package:medtrace/services/supabase/alert_service.dart';
import 'package:medtrace/services/supabase/auth_service.dart';
import 'package:medtrace/services/supabase/chatbot_service.dart';
import 'package:medtrace/services/supabase/dashboard_service.dart';
import 'package:medtrace/services/supabase/doctor_code_service.dart';
import 'package:medtrace/services/supabase/doctor_service.dart';
import 'package:medtrace/services/supabase/location_service.dart';
import 'package:medtrace/services/supabase/medication_log_service.dart';
import 'package:medtrace/services/supabase/medication_service.dart';
import 'package:medtrace/services/supabase/notification_data_service.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/profile_service.dart';
import 'package:medtrace/services/supabase/reminder_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';
import 'package:medtrace/services/supabase/tb_case_service.dart';
import 'package:medtrace/services/supabase/therapy_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client;
  final Logger logger;
  late final SupabaseServiceContext context;
  late final ProfileService profiles;
  late final DoctorService doctors;
  late final DoctorCodeService doctorCodes;
  late final PatientService patients;
  late final TbCaseService tbCases;
  late final AuthService auth;
  late final TherapyService therapies;
  late final MedicationService medications;
  late final MedicationLogService medicationLogs;
  late final ReminderService reminders;
  late final AlertService alerts;
  late final NotificationDataService notificationData;
  late final LocationService locations;
  late final ChatbotService chatbot;
  late final DashboardService dashboard;

  SupabaseService({
    required this.client,
    Logger? logger,
  }) : logger = logger ?? Logger() {
    context = SupabaseServiceContext(client: client, logger: this.logger);
    profiles = ProfileService(context);
    doctors = DoctorService(context, profiles);
    doctorCodes = DoctorCodeService(context, doctors);
    patients = PatientService(context, doctors);
    tbCases = TbCaseService(context, patients);
    auth = AuthService(context, profiles, doctorCodes);
    therapies = TherapyService(context, doctors);
    medications = MedicationService(context);
    medicationLogs = MedicationLogService(context, patients);
    reminders = ReminderService(context, patients);
    alerts = AlertService(context, patients);
    notificationData = NotificationDataService(context);
    locations = LocationService(context, patients);
    chatbot = ChatbotService(context, patients);
    dashboard = DashboardService(
      doctors: doctors,
      therapies: therapies,
      medicationLogs: medicationLogs,
      alerts: alerts,
    );
  }

  Future<UserModel> registerPatient({
    required String email,
    required String password,
    required String doctorCode,
    required String fullName,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? gender,
    String? address,
  }) {
    return auth.registerPatient(
      email: email,
      password: password,
      doctorCode: doctorCode,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber,
      gender: gender,
      address: address,
    );
  }

  Future<UserModel> completePatientRegistrationAfterVerification({
    required String userId,
    required String email,
    required String fullName,
    required String doctorCode,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? gender,
    String? address,
  }) {
    return auth.completePatientRegistrationAfterVerification(
      userId: userId,
      email: email,
      fullName: fullName,
      doctorCode: doctorCode,
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber,
      gender: gender,
      address: address,
    );
  }

  Future<void> resendPatientVerificationEmail(String email) {
    return auth.resendPatientVerificationEmail(email);
  }

  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) {
    return auth.loginUser(email: email, password: password);
  }

  Future<void> logout() => auth.logout();

  Future<void> resetPassword(String email) => auth.resetPassword(email);

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

  Future<DoctorCodeModel> validateDoctorCode(String code) {
    return doctorCodes.validate(code);
  }

  Future<List<UserModel>> getMyPatients(String doctorId) {
    return doctors.getPatients(doctorId);
  }

  Future<UserModel?> getMyDoctor(String patientId) {
    return doctors.getDoctorForPatient(patientId);
  }

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

  Future<TreatmentModel?> getPatientTreatment(String patientId) {
    return therapies.getPatientTreatment(patientId);
  }

  Future<List<TreatmentModel>> getDoctorPatientsTreatments(String doctorId) {
    return therapies.getDoctorPatientsTreatments(doctorId);
  }

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
}
