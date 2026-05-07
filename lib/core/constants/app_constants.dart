class AppConstants {
  // Role Constants
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';

  // Treatment Phase Constants
  static const String phaseIntensive = 'intensive';
  static const String phaseContinuation = 'continuation';

  // Treatment Status Constants
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusDefaulted = 'defaulted';

  // Medication Log Status
  static const String medicationTaken = 'taken';
  static const String medicationMissed = 'missed';
  static const String medicationSkipped = 'skipped';

  // Alert Severity
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';

  // Search & Filter
  static const int minSearchLength = 2;
  static const int debounceMilliseconds = 500;

  // Map Constants
  static const double defaultMapZoom = 12.0;
  static const double clusterZoomThreshold = 15.0;

  // Notification Constants
  static const String channelIdMedication = 'medication_reminder';
  static const String channelIdAlert = 'doctor_alerts';

  // Date Format
  static const String dateFormatDisplay = 'dd MMM yyyy';
  static const String dateTimeFormatDisplay = 'dd MMM yyyy HH:mm';

  // Empty States
  static const String noDataFoundMessage = 'No data found';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String unknownErrorMessage =
      'Something went wrong. Please try again.';
}

// Doctor Code Constants
class DoctorCodeConstants {
  static const int codeLength = 6;
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
}

// Chatbot Constants
class ChatbotConstants {
  static const int maxContextMessages = 10;
  static const Duration conversationTimeout = Duration(minutes: 5);
  static const String systemPromptEN =
      '''You are a tuberculosis (TB) health assistant for the MedTrace application.
Your role is to provide accurate, clear, and supportive health information.

Important Guidelines:
1. Explain concepts in simple, easy-to-understand language
2. Base medical information on WHO TB guidelines
3. Be empathetic, calm, and helpful
4. Do NOT provide diagnoses or prescribe medications
5. For serious concerns, advise users to consult their healthcare provider
6. Provide context-specific responses based on patient information when available
7. Emphasize the importance of treatment adherence
8. Provide educational content about TB transmission and prevention

Remember: You are a support tool, not a replacement for professional medical advice.''';
}

// Treatment Constants
class TreatmentConstants {
  static const int intensivePhaseMonths = 2;
  static const int continuationPhaseMonths = 4;
  static const double minAdherencePercentageForCompletion = 80.0;
  static const int maxMissedDosesBeforeAlert = 2;
}
