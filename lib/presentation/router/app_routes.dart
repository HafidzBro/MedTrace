class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String patientRegister = '/patient-register';

  // Patient
  static const String patientDashboard = '/patient-dashboard';
  static const String treatment = '/patient/treatment';
  static const String adherenceHistory = '/patient/adherence-history';
  static const String medicationSchedule = '/patient/medications';
  static const String chatbot = '/patient/chatbot';
  static const String tbMap = '/patient/map';
  static const String reminders = '/patient/reminders';
  static const String patientProfile = '/patient/profile';
  static const String patientNotifications = '/patient/notifications';

  // Doctor
  static const String doctorDashboard = '/doctor-dashboard';
  static const String patientManagement = '/doctor/patients';
  static const String patientDetail = '/doctor/patients/detail';
  static const String alerts = '/doctor/alerts';
  static const String adherenceMonitoring = '/doctor/adherence';
  static const String analytics = adherenceMonitoring;
  static const String doctorMap = '/doctor/map';
  static const String doctorProfile = '/doctor/profile';
}
