import 'package:medtrace/data/models/alert_model.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/patient_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
import 'package:medtrace/data/models/therapy_status_history_model.dart';
import 'package:medtrace/services/supabase/alert_service.dart';
import 'package:medtrace/services/supabase/doctor_service.dart';
import 'package:medtrace/services/supabase/medication_log_service.dart';
import 'package:medtrace/services/supabase/therapy_service.dart';

class PatientDashboardSummary {
  final TreatmentModel? therapy;
  final List<MedicationLogModel> recentLogs;

  const PatientDashboardSummary({
    required this.therapy,
    required this.recentLogs,
  });

  double get adherencePercentage => therapy?.adherencePercentage ?? 0;
}

class DoctorDashboardSummary {
  final List<UserModel> patients;
  final List<TreatmentModel> therapies;
  final List<AlertModel> alerts;
  final List<DoctorPatientDirectoryItem> directoryItems;

  const DoctorDashboardSummary({
    required this.patients,
    required this.therapies,
    required this.alerts,
    this.directoryItems = const [],
  });

  int get totalPatients => patients.length;
  int get activeTherapies =>
      therapies.where((therapy) => therapy.isOngoing).length;
  int get highPriorityAlerts => alerts
      .where(
          (alert) => alert.severity == 'high' || alert.severity == 'critical')
      .length;
}

class DoctorPatientDirectoryItem {
  final PatientModel patient;
  final UserModel profile;
  final TreatmentModel? therapy;
  final MedicationLogModel? lastLog;
  final int missedCount;
  final List<MedicationLogModel> logs;
  final List<TherapyStatusHistoryModel> statusHistory;

  const DoctorPatientDirectoryItem({
    required this.patient,
    required this.profile,
    this.therapy,
    this.lastLog,
    this.missedCount = 0,
    this.logs = const [],
    this.statusHistory = const [],
  });
}

class DashboardService {
  final DoctorService doctors;
  final TherapyService therapies;
  final MedicationLogService medicationLogs;
  final AlertService alerts;

  const DashboardService({
    required this.doctors,
    required this.therapies,
    required this.medicationLogs,
    required this.alerts,
  });

  Future<PatientDashboardSummary> patientSummary(String patientId) async {
    final therapy = await therapies.getPatientTreatment(patientId);
    final logs = therapy == null
        ? <MedicationLogModel>[]
        : await medicationLogs.ensureWeeklyLogs(
            patientId: patientId,
            therapy: therapy,
          );

    return PatientDashboardSummary(
      therapy: therapy,
      recentLogs: logs,
    );
  }

  Future<DoctorDashboardSummary> doctorSummary(String doctorId) async {
    final patientRecords = await doctors.getPatientRecords(doctorId);
    final patients = patientRecords.map((record) => record.profile).toList();
    final therapyRows = await therapies.getDoctorPatientsTreatments(doctorId);
    final alertRows = await alerts.listForDoctor(doctorId);
    final patientIds =
        patientRecords.map((record) => record.patient.patientId).toList();
    final medicationLogs = await medicationLogsForDirectory(patientIds);
    final therapiesByPatient = <String, TreatmentModel>{};
    for (final therapy in therapyRows) {
      therapiesByPatient.putIfAbsent(therapy.patientId, () => therapy);
    }
    final statusHistoryEntries = await Future.wait(
      therapyRows.map(
        (therapy) async => MapEntry(
          therapy.id,
          await therapies.listStatusHistory(therapy.id),
        ),
      ),
    );
    final statusHistoryByTherapy =
        Map<String, List<TherapyStatusHistoryModel>>.fromEntries(
      statusHistoryEntries,
    );
    final logsByPatient = <String, List<MedicationLogModel>>{};
    for (final log in medicationLogs) {
      logsByPatient.putIfAbsent(log.patientId, () => []).add(log);
    }
    final directoryItems = patientRecords.map((record) {
      final logs = logsByPatient[record.patient.patientId] ?? const [];
      final therapy = therapiesByPatient[record.patient.patientId];
      return DoctorPatientDirectoryItem(
        patient: record.patient,
        profile: record.profile,
        therapy: therapy,
        lastLog: logs.isEmpty ? null : logs.first,
        missedCount: logs.where((log) => log.isMissed).length,
        logs: logs,
        statusHistory: therapy == null
            ? const []
            : statusHistoryByTherapy[therapy.id] ?? const [],
      );
    }).toList();

    return DoctorDashboardSummary(
      patients: patients,
      therapies: therapyRows,
      alerts: alertRows,
      directoryItems: directoryItems,
    );
  }

  Future<List<MedicationLogModel>> medicationLogsForDirectory(
    List<String> patientIds,
  ) {
    return medicationLogs.listForPatients(patientIds);
  }
}
