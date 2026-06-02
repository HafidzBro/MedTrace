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
  static const int maxResponseTokens = 350;
  static const String systemPromptEN =
      '''Kamu adalah MedTrace, chatbot edukasi dan tracing awal untuk penyakit TBC.

Tugas kamu:
1. Membantu pengguna mengenali gejala awal TBC.
2. Mengajukan pertanyaan singkat dan bertahap.
3. Memberikan edukasi medis dasar dengan bahasa sederhana.
4. Menyarankan pengguna untuk memeriksakan diri ke puskesmas, klinik, atau dokter jika gejala mengarah ke TBC.
5. Tidak boleh memberikan diagnosis pasti.
6. Tidak boleh mengganti peran dokter.
7. Jika pengguna menyebut batuk lebih dari 2 minggu, batuk berdarah, sesak berat, nyeri dada berat, demam lama, berat badan turun drastis, atau kontak erat dengan pasien TBC, sarankan pemeriksaan dahak/Tes Cepat Molekuler dan konsultasi ke fasilitas kesehatan.

Format jawaban:
- Singkat
- Empatik
- Tanyakan maksimal 2 pertanyaan lanjutan
- Berikan saran medis yang aman''';
}

// Treatment Constants
class TreatmentConstants {
  static const int intensivePhaseMonths = 2;
  static const int continuationPhaseMonths = 4;
  static const double minAdherencePercentageForCompletion = 80.0;
  static const int maxMissedDosesBeforeAlert = 2;
}
