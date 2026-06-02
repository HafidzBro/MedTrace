import 'package:logger/logger.dart';
import 'package:medtrace/data/models/doctor_model.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/notification_model.dart';
import 'package:medtrace/data/models/patient_location_model.dart';
import 'package:medtrace/data/models/patient_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/data/models/reminder_model.dart';
import 'package:medtrace/data/models/tb_case_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
import 'package:medtrace/data/models/therapy_status_history_model.dart';
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
    therapies = TherapyService(context, doctors, patients);
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
  }) {
    return auth.registerPatient(
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

  Future<UserModel> completePatientRegistrationAfterVerification({
    required String userId,
    required String email,
    required String fullName,
    required String doctorCode,
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
  }) {
    return auth.completePatientRegistrationAfterVerification(
      userId: userId,
      email: email,
      fullName: fullName,
      doctorCode: doctorCode,
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

  Future<DoctorProfileSummary> doctorProfileSummary(
      String idOrAuthUserId) async {
    UserModel profile;
    try {
      profile = await profiles.getByProfileId(idOrAuthUserId);
    } catch (_) {
      profile = await profiles.getByAuthUserId(idOrAuthUserId);
    }

    final doctor = await doctors.getByAuthUserId(idOrAuthUserId);
    return DoctorProfileSummary(profile: profile, doctor: doctor);
  }

  Future<PatientProfileSummary> patientProfileSummary(String userId) async {
    final profile = await profiles.getByAuthUserId(userId);
    final patient = await patients.getByAuthUserId(userId);
    final doctor = await patients.getDoctorProfile(patient.id);
    final facilityName = await patients.getDoctorFacilityName(patient.id);
    final reminder = await reminders.ensureMedicationReminder(
      patientId: patient.id,
    );

    return PatientProfileSummary(
      profile: profile,
      patient: patient,
      doctor: doctor,
      facilityName: facilityName,
      medicationReminder: reminder,
    );
  }

  Future<List<NotificationModel>> patientNotifications(String userId) async {
    final profile = await profiles.getByAuthUserId(userId);
    return notificationData.listForProfile(profile.id);
  }

  Future<NotificationModel> markPatientNotificationRead(
    String notificationId,
  ) {
    return notificationData.markRead(notificationId);
  }

  Future<PatientDetailSummary> patientDetailSummary(String patientId) async {
    final patient = await patients.getById(patientId);
    final profile = await patients.getProfile(patient.id);
    final cases = await tbCases.listForPatient(patient.id);
    final therapy = await therapies.getLatestPatientTreatment(patient.id);
    final plan =
        therapy == null ? null : await medications.currentIntakePlan(therapy);
    final logs = await medicationLogs.listForPatient(patient.id);
    final statusHistory = therapy == null
        ? <TherapyStatusHistoryModel>[]
        : await therapies.listStatusHistory(therapy.id);

    return PatientDetailSummary(
      patient: patient,
      profile: profile,
      tbCase: cases.isEmpty ? null : cases.first,
      therapy: therapy,
      intakePlan: plan,
      recentLogs: logs.take(7).toList(),
      statusHistory: statusHistory,
    );
  }

  Future<DoctorMapSummary> doctorMapSummary(String doctorId) async {
    final dashboardSummary = await dashboard.doctorSummary(doctorId);
    final patientIds = dashboardSummary.directoryItems
        .map((item) => item.patient.patientId)
        .toList();
    final currentLocations = await locations.listCurrentForPatients(patientIds);
    final locationsByPatient = <String, PatientLocationModel>{};
    for (final location in currentLocations) {
      locationsByPatient.putIfAbsent(location.patientId, () => location);
    }

    final cases = dashboardSummary.directoryItems
        .map((item) {
          final location = locationsByPatient[item.patient.patientId];
          if (location == null) return null;
          return DoctorMapCase(item: item, location: location);
        })
        .whereType<DoctorMapCase>()
        .toList();

    return DoctorMapSummary(cases: cases);
  }

  Future<TreatmentModel> resetTherapyProgress(String treatmentId) {
    return therapies.resetProgress(treatmentId);
  }

  Future<PatientProfileSummary> updateMedicationReminderPreference({
    required String userId,
    DateTime? reminderTime,
    bool? enabled,
  }) async {
    final patient = await patients.getByAuthUserId(userId);
    await reminders.updateMedicationReminder(
      patientId: patient.id,
      reminderTime: reminderTime,
      enabled: null,
    );
    if (reminderTime != null) {
      await medicationLogs.reschedulePendingLogsForReminderTime(
        patientId: patient.id,
        reminderTime: reminderTime,
      );
    }

    return patientProfileSummary(userId);
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

  Future<List<DoctorCodeModel>> listDoctorCodes(String doctorId) {
    return doctorCodes.listForDoctor(doctorId);
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

  Future<TreatmentModel?> getLatestPatientTreatment(String patientId) {
    return therapies.getLatestPatientTreatment(patientId);
  }

  Future<List<TreatmentModel>> getDoctorPatientsTreatments(String doctorId) {
    return therapies.getDoctorPatientsTreatments(doctorId);
  }

  Future<void> logTodayDose(String patientId) async {
    await medicationLogs.logTodayDose(patientId);
  }

  Future<List<MedicationLogModel>> patientAdherenceHistory(
    String patientId,
  ) async {
    final therapy = await therapies.getPatientTreatment(patientId);
    if (therapy != null) {
      await medicationLogs.ensureWeeklyLogs(
        patientId: patientId,
        therapy: therapy,
      );
    }

    return medicationLogs.listForPatient(patientId);
  }

  Future<MedicationIntakePlan?> currentPatientIntakePlan(
    String patientId,
  ) async {
    final therapy = await therapies.getPatientTreatment(patientId);
    if (therapy == null) return null;

    await medicationLogs.ensureWeeklyLogs(
      patientId: patientId,
      therapy: therapy,
    );
    final plan = await medications.currentIntakePlan(therapy);
    final todayLog = await medicationLogs.todayLog(patientId);
    final reminder = await reminders.ensureMedicationReminder(
      patientId: patientId,
    );
    if (plan == null) return null;

    return MedicationIntakePlan(
      phaseId: plan.phaseId,
      phaseName: plan.phaseName,
      startMonth: plan.startMonth,
      endMonth: plan.endMonth,
      intakeTime: reminder.reminderTime,
      instructions: plan.instructions,
      items: plan.items,
      todayLog: todayLog,
    );
  }

  Future<TreatmentModel> updateTreatment({
    required String treatmentId,
    String? phase,
    String? status,
    String? historyStatus,
    double? adherencePercentage,
    String? notes,
  }) {
    return therapies.updateTreatment(
      treatmentId: treatmentId,
      phase: phase,
      status: status,
      historyStatus: historyStatus,
      adherencePercentage: adherencePercentage,
      notes: notes,
    );
  }
}

class PatientProfileSummary {
  final UserModel profile;
  final PatientModel patient;
  final UserModel? doctor;
  final String? facilityName;
  final ReminderModel medicationReminder;

  const PatientProfileSummary({
    required this.profile,
    required this.patient,
    required this.doctor,
    this.facilityName,
    required this.medicationReminder,
  });

  bool get remindersEnabled => medicationReminder.status != 'cancelled';
}

class PatientDetailSummary {
  final PatientModel patient;
  final UserModel profile;
  final TbCaseModel? tbCase;
  final TreatmentModel? therapy;
  final MedicationIntakePlan? intakePlan;
  final List<MedicationLogModel> recentLogs;
  final List<TherapyStatusHistoryModel> statusHistory;

  const PatientDetailSummary({
    required this.patient,
    required this.profile,
    required this.tbCase,
    required this.therapy,
    required this.intakePlan,
    required this.recentLogs,
    required this.statusHistory,
  });
}

class DoctorMapSummary {
  final List<DoctorMapCase> cases;

  const DoctorMapSummary({required this.cases});

  int get totalInView => cases.length;
  int get highRiskCount => cases.where((item) => item.isHighRisk).length;
  int get activeCount => cases.where((item) => item.isActive).length;
  int get completedCount => cases.where((item) => item.isCompleted).length;
}

class DoctorMapCase {
  final DoctorPatientDirectoryItem item;
  final PatientLocationModel location;

  const DoctorMapCase({
    required this.item,
    required this.location,
  });

  bool get isCompleted => item.therapy?.isCompleted ?? false;
  bool get isActive => (item.therapy?.isOngoing ?? false) && !isHighRisk;
  bool get isHighRisk {
    final therapy = item.therapy;
    return item.missedCount > 0 ||
        (therapy?.isDefaulted ?? false) ||
        ((therapy?.isOngoing ?? false) &&
            (therapy?.adherencePercentage ?? 100) < 80);
  }

  String get patientName {
    final fullName = item.profile.fullName.trim();
    if (fullName.isNotEmpty) return fullName;
    final email = item.profile.email.trim();
    if (email.isNotEmpty) return email;
    return 'Patient';
  }

  String get patientCode {
    final value = item.patient.patientCode;
    if (value != null && value.trim().isNotEmpty) return value.trim();
    return item.patient.patientId;
  }
}

class DoctorProfileSummary {
  final UserModel profile;
  final DoctorModel? doctor;

  const DoctorProfileSummary({
    required this.profile,
    required this.doctor,
  });
}
