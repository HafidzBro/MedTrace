import 'package:medtrace/data/models/alert_model.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
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

  const DoctorDashboardSummary({
    required this.patients,
    required this.therapies,
    required this.alerts,
  });

  int get totalPatients => patients.length;
  int get activeTherapies =>
      therapies.where((therapy) => therapy.isOngoing).length;
  int get highPriorityAlerts => alerts
      .where(
          (alert) => alert.severity == 'high' || alert.severity == 'critical')
      .length;
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
    final logs = await medicationLogs.listForPatient(patientId);

    return PatientDashboardSummary(
      therapy: therapy,
      recentLogs: logs.take(10).toList(),
    );
  }

  Future<DoctorDashboardSummary> doctorSummary(String doctorId) async {
    final patients = await doctors.getPatients(doctorId);
    final therapyRows = await therapies.getDoctorPatientsTreatments(doctorId);
    final alertRows = await alerts.listForDoctor(doctorId);

    return DoctorDashboardSummary(
      patients: patients,
      therapies: therapyRows,
      alerts: alertRows,
    );
  }
}
