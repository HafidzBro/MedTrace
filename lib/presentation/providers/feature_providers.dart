import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/data/datasources/remote/supabase_remote_datasource.dart';
import 'package:medtrace/data/models/models.dart';
import 'package:medtrace/data/repositories/repositories.dart';
import 'package:medtrace/domain/entities/entities.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/services/connectivity_service.dart';
import 'package:medtrace/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

// ============================================================
// DATASOURCE PROVIDERS
// ============================================================

final remoteDataSourceProvider = Provider<SupabaseRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRemoteDataSource(client: client);
});

// ============================================================
// REPOSITORY PROVIDERS
// ============================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return AuthRepository(remoteDataSource: dataSource);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return UserRepository(remoteDataSource: dataSource);
});

final doctorCodeRepositoryProvider = Provider<DoctorCodeRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return DoctorCodeRepository(remoteDataSource: dataSource);
});

final treatmentRepositoryProvider = Provider<TreatmentRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return TreatmentRepository(remoteDataSource: dataSource);
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return MedicationRepository(remoteDataSource: dataSource);
});

final medicationLogRepositoryProvider = Provider<MedicationLogRepository>((
  ref,
) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return MedicationLogRepository(remoteDataSource: dataSource);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return ReminderRepository(remoteDataSource: dataSource);
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return LocationRepository(remoteDataSource: dataSource);
});

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return ChatbotRepository(remoteDataSource: dataSource);
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return AlertRepository(remoteDataSource: dataSource);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

// ============================================================
// TREATMENT PROVIDER
// ============================================================

class TreatmentState {
  final bool isLoading;
  final TreatmentModel? treatment;
  final String? error;

  TreatmentState({this.isLoading = false, this.treatment, this.error});

  TreatmentState copyWith({
    bool? isLoading,
    TreatmentModel? treatment,
    String? error,
  }) {
    return TreatmentState(
      isLoading: isLoading ?? this.isLoading,
      treatment: treatment ?? this.treatment,
      error: error ?? this.error,
    );
  }
}

class TreatmentNotifier extends StateNotifier<TreatmentState> {
  final TreatmentRepository repository;
  final String patientId;
  final SupabaseClient client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  TreatmentNotifier({
    required this.repository,
    required this.patientId,
    required this.client,
  }) : super(TreatmentState()) {
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _subscription?.cancel();
    _subscription = client
        .from('treatments')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .listen((rows) {
          if (rows.isNotEmpty) {
            final treatment = TreatmentModel.fromJson(rows.first);
            state = state.copyWith(treatment: treatment, isLoading: false);
          }
        });
  }

  Future<void> loadTreatment() async {
    try {
      state = state.copyWith(isLoading: true);
      final treatment = await repository.getPatientTreatment(patientId);
      state = state.copyWith(treatment: treatment, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final patientTreatmentProvider =
    StateNotifierProvider.family<TreatmentNotifier, TreatmentState, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(treatmentRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final notifier = TreatmentNotifier(
    repository: repository,
    patientId: patientId,
    client: client,
  );
  notifier.loadTreatment();
  return notifier;
});

// ============================================================
// MEDICATIONS PROVIDER
// ============================================================

class MedicationsState {
  final bool isLoading;
  final List<MedicationModel> medications;
  final String? error;

  MedicationsState({
    this.isLoading = false,
    this.medications = const [],
    this.error,
  });

  MedicationsState copyWith({
    bool? isLoading,
    List<MedicationModel>? medications,
    String? error,
  }) {
    return MedicationsState(
      isLoading: isLoading ?? this.isLoading,
      medications: medications ?? this.medications,
      error: error ?? this.error,
    );
  }
}

class MedicationsNotifier extends StateNotifier<MedicationsState> {
  final MedicationRepository repository;
  final String treatmentId;

  MedicationsNotifier({required this.repository, required this.treatmentId})
      : super(MedicationsState());

  Future<void> loadMedications() async {
    try {
      state = state.copyWith(isLoading: true);
      final medications = await repository.getTreatmentMedications(treatmentId);
      state = state.copyWith(medications: medications, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final treatmentMedicationsProvider =
    StateNotifierProvider.family<MedicationsNotifier, MedicationsState, String>(
  (ref, treatmentId) {
    final repository = ref.watch(medicationRepositoryProvider);
    final notifier = MedicationsNotifier(
      repository: repository,
      treatmentId: treatmentId,
    );
    notifier.loadMedications();
    return notifier;
  },
);

// ============================================================
// MEDICATION LOGS PROVIDER
// ============================================================

class MedicationLogsState {
  final bool isLoading;
  final List<MedicationLogModel> logs;
  final String? error;
  final double adherencePercentage;
  final List<double> weeklyTrend;
  final List<double> monthlyTrend;

  MedicationLogsState({
    this.isLoading = false,
    this.logs = const [],
    this.error,
    this.adherencePercentage = 0.0,
    this.weeklyTrend = const [],
    this.monthlyTrend = const [],
  });

  MedicationLogsState copyWith({
    bool? isLoading,
    List<MedicationLogModel>? logs,
    String? error,
    double? adherencePercentage,
    List<double>? weeklyTrend,
    List<double>? monthlyTrend,
  }) {
    return MedicationLogsState(
      isLoading: isLoading ?? this.isLoading,
      logs: logs ?? this.logs,
      error: error ?? this.error,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
    );
  }
}

class MedicationLogsNotifier extends StateNotifier<MedicationLogsState> {
  final MedicationLogRepository repository;
  final TreatmentRepository treatmentRepository;
  final AlertRepository alertRepository;
  final SupabaseClient client;
  final String patientId;
  StreamSubscription<List<Map<String, dynamic>>>? _logsSubscription;

  MedicationLogsNotifier({
    required this.repository,
    required this.treatmentRepository,
    required this.alertRepository,
    required this.client,
    required this.patientId,
  }) : super(MedicationLogsState()) {
    _subscribeRealtime();
    _reconnectSubscription = ConnectivityService.instance.onReconnect.listen((_) {
      _subscribeRealtime();
      loadMedicationLogs();
    });
  }

  StreamSubscription<void>? _reconnectSubscription;

  void _subscribeRealtime() {
    _logsSubscription?.cancel();
    _logsSubscription = client
        .from('medication_logs')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .listen((rows) {
          final logs = rows.map(MedicationLogModel.fromJson).toList();
          double adherence = 0.0;
          if (logs.isNotEmpty) {
            final takenCount = logs.where((log) => log.isTaken).length;
            adherence = (takenCount / logs.length) * 100;
          }

          state = state.copyWith(
            logs: logs,
            adherencePercentage: adherence,
            isLoading: false,
            error: null,
          );
        });
  }

  Future<void> loadMedicationLogs() async {
    try {
      state = state.copyWith(isLoading: true);
      final logs = await repository.getPatientMedicationLogs(patientId);

      double adherence = 0.0;
      if (logs.isNotEmpty) {
        final takenCount = logs.where((log) => log.isTaken).length;
        adherence = (takenCount / logs.length) * 100;
      }

      final weeklyTrend = _calculateTrend(logs, 7);
      final monthlyTrend = _calculateTrend(logs, 30);

      state = state.copyWith(
        logs: logs,
        adherencePercentage: adherence,
        weeklyTrend: weeklyTrend,
        monthlyTrend: monthlyTrend,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  List<double> _calculateTrend(List<MedicationLogModel> logs, int days) {
    final now = DateTime.now();
    final trend = <double>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayLogs = logs.where((l) =>
          l.scheduledDate.year == date.year &&
          l.scheduledDate.month == date.month &&
          l.scheduledDate.day == date.day);
      if (dayLogs.isEmpty) {
        trend.add(-1); // no data
      } else {
        final taken = dayLogs.where((l) => l.isTaken).length;
        trend.add((taken / dayLogs.length) * 100);
      }
    }
    return trend;
  }

  Future<void> markMedicationTaken(String logId) async {
    try {
      await repository.updateMedicationLog(logId: logId, status: 'taken');
      await loadMedicationLogs();
      await _syncAdherence();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markMedicationMissed(String logId) async {
    try {
      await repository.updateMedicationLog(logId: logId, status: 'missed');
      await loadMedicationLogs();
      await _syncAdherence();
      await _checkAndGenerateAlerts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _syncAdherence() async {
    try {
      final treatment = await treatmentRepository.getPatientTreatment(patientId);
      if (treatment != null) {
        await treatmentRepository.updateTreatment(
          treatmentId: treatment.id,
          adherencePercentage: state.adherencePercentage,
        );
      }
    } catch (_) {}
  }

  Future<void> _checkAndGenerateAlerts() async {
    try {
      // Alert if adherence drops below 60%
      if (state.adherencePercentage < 60 && state.logs.length >= 3) {
        final treatment = await treatmentRepository.getPatientTreatment(patientId);
        if (treatment == null) return;

        await alertRepository.createAlert(
          doctorId: treatment.doctorId,
          patientId: patientId,
          alertType: 'missed_medication',
          severity: state.adherencePercentage < 40 ? 'critical' : 'high',
          title: 'Low adherence: ${state.adherencePercentage.toStringAsFixed(0)}%',
          description:
              'Patient adherence has dropped to ${state.adherencePercentage.toStringAsFixed(1)}%.',
        );
      }

      // Alert if 2+ consecutive missed
      final recentLogs = state.logs.take(5).toList();
      int consecutiveMissed = 0;
      for (final log in recentLogs) {
        if (log.isMissed) {
          consecutiveMissed++;
        } else {
          break;
        }
      }
      if (consecutiveMissed >= 2) {
        final treatment = await treatmentRepository.getPatientTreatment(patientId);
        if (treatment == null) return;

        await alertRepository.createAlert(
          doctorId: treatment.doctorId,
          patientId: patientId,
          alertType: 'missed_medication',
          severity: consecutiveMissed >= 3 ? 'critical' : 'high',
          title: 'Missed $consecutiveMissed consecutive doses',
          description:
              'Patient has missed $consecutiveMissed consecutive medication doses.',
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    _reconnectSubscription?.cancel();
    super.dispose();
  }
}

final patientMedicationLogsProvider = StateNotifierProvider.family<
    MedicationLogsNotifier, MedicationLogsState, String>((ref, patientId) {
  final repository = ref.watch(medicationLogRepositoryProvider);
  final treatmentRepository = ref.watch(treatmentRepositoryProvider);
  final alertRepository = ref.watch(alertRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final notifier = MedicationLogsNotifier(
    repository: repository,
    treatmentRepository: treatmentRepository,
    alertRepository: alertRepository,
    client: client,
    patientId: patientId,
  );
  notifier.loadMedicationLogs();
  return notifier;
});

// ============================================================
// REMINDERS PROVIDER
// ============================================================

class RemindersState {
  final bool isLoading;
  final List<ReminderModel> reminders;
  final String? error;

  RemindersState({
    this.isLoading = false,
    this.reminders = const [],
    this.error,
  });

  RemindersState copyWith({
    bool? isLoading,
    List<ReminderModel>? reminders,
    String? error,
  }) {
    return RemindersState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
      error: error ?? this.error,
    );
  }
}

class RemindersNotifier extends StateNotifier<RemindersState> {
  final ReminderRepository repository;
  final NotificationService notificationService;
  final String patientId;

  RemindersNotifier({
    required this.repository,
    required this.notificationService,
    required this.patientId,
  }) : super(RemindersState());

  Future<void> loadReminders() async {
    try {
      state = state.copyWith(isLoading: true);
      final reminders = await repository.getPatientReminders(patientId);
      state = state.copyWith(reminders: reminders, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createReminder({
    required String title,
    String? description,
    required String reminderType,
    required DateTime scheduledDate,
    required DateTime scheduledTime,
  }) async {
    try {
      final created = await repository.createReminder(
        patientId: patientId,
        title: title,
        description: description,
        reminderType: reminderType,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );

      await notificationService.scheduleReminderNotification(
        id: created.id.hashCode,
        title: created.title,
        body: created.description ?? 'Reminder from MedTrace',
        when: DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          scheduledTime.hour,
          scheduledTime.minute,
        ),
      );

      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateReminder({
    required String reminderId,
    required String title,
    String? description,
    required DateTime scheduledDate,
    required DateTime scheduledTime,
  }) async {
    try {
      final updated = await repository.updateReminder(
        reminderId: reminderId,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );

      await notificationService.cancel(reminderId.hashCode);
      await notificationService.scheduleReminderNotification(
        id: reminderId.hashCode,
        title: updated.title,
        body: updated.description ?? 'Reminder from MedTrace',
        when: DateTime(
          updated.scheduledDate.year,
          updated.scheduledDate.month,
          updated.scheduledDate.day,
          updated.scheduledTime.hour,
          updated.scheduledTime.minute,
        ),
      );

      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await repository.deleteReminder(reminderId);
      await notificationService.cancel(reminderId.hashCode);
      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final patientRemindersProvider =
    StateNotifierProvider.family<RemindersNotifier, RemindersState, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(reminderRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final notifier = RemindersNotifier(
    repository: repository,
    notificationService: notificationService,
    patientId: patientId,
  );
  notifier.loadReminders();
  return notifier;
});

// ============================================================
// LOCATIONS PROVIDER
// ============================================================

class LocationsState {
  final bool isLoading;
  final List<PatientLocationModel> locations;
  final String? error;

  LocationsState({
    this.isLoading = false,
    this.locations = const [],
    this.error,
  });

  LocationsState copyWith({
    bool? isLoading,
    List<PatientLocationModel>? locations,
    String? error,
  }) {
    return LocationsState(
      isLoading: isLoading ?? this.isLoading,
      locations: locations ?? this.locations,
      error: error ?? this.error,
    );
  }
}

class LocationsNotifier extends StateNotifier<LocationsState> {
  final LocationRepository repository;
  final String patientId;

  LocationsNotifier({required this.repository, required this.patientId})
      : super(LocationsState());

  Future<void> loadLocations() async {
    try {
      state = state.copyWith(isLoading: true);
      final locations = await repository.getPatientLocations(patientId);
      state = state.copyWith(locations: locations, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> recordLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await repository.recordLocation(
        patientId: patientId,
        latitude: latitude,
        longitude: longitude,
      );
      await loadLocations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final patientLocationsProvider =
    StateNotifierProvider.family<LocationsNotifier, LocationsState, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(locationRepositoryProvider);
  final notifier = LocationsNotifier(
    repository: repository,
    patientId: patientId,
  );
  notifier.loadLocations();
  return notifier;
});

// ============================================================
// CHATBOT PROVIDERS
// ============================================================

class ChatbotConversationsState {
  final bool isLoading;
  final List<ChatbotConversation> conversations;
  final String? error;

  const ChatbotConversationsState({
    this.isLoading = false,
    this.conversations = const [],
    this.error,
  });

  ChatbotConversationsState copyWith({
    bool? isLoading,
    List<ChatbotConversation>? conversations,
    String? error,
  }) {
    return ChatbotConversationsState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      error: error ?? this.error,
    );
  }
}

class ChatbotConversationsNotifier
    extends StateNotifier<ChatbotConversationsState> {
  final ChatbotRepository repository;
  final String patientId;

  ChatbotConversationsNotifier({
    required this.repository,
    required this.patientId,
  }) : super(const ChatbotConversationsState());

  Future<void> loadConversations() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final conversations = await repository.getPatientConversations(patientId);
      state = state.copyWith(isLoading: false, conversations: conversations);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ChatbotConversation> createConversation() async {
    final conversation = await repository.createConversation(patientId);
    await loadConversations();
    return conversation;
  }
}

final chatbotConversationsProvider = StateNotifierProvider.family<
    ChatbotConversationsNotifier,
    ChatbotConversationsState,
    String>((ref, patientId) {
  final repository = ref.watch(chatbotRepositoryProvider);
  final notifier = ChatbotConversationsNotifier(
    repository: repository,
    patientId: patientId,
  );
  notifier.loadConversations();
  return notifier;
});

class ChatbotMessagesState {
  final bool isLoading;
  final List<ChatbotMessageModel> messages;
  final String? error;

  const ChatbotMessagesState({
    this.isLoading = false,
    this.messages = const [],
    this.error,
  });

  ChatbotMessagesState copyWith({
    bool? isLoading,
    List<ChatbotMessageModel>? messages,
    String? error,
  }) {
    return ChatbotMessagesState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      error: error ?? this.error,
    );
  }
}

class ChatbotMessagesNotifier extends StateNotifier<ChatbotMessagesState> {
  final ChatbotRepository repository;
  final String conversationId;

  ChatbotMessagesNotifier({
    required this.repository,
    required this.conversationId,
  }) : super(const ChatbotMessagesState());

  Future<void> loadMessages() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final messages = await repository.getConversationMessages(conversationId);
      state = state.copyWith(isLoading: false, messages: messages);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ChatbotMessageModel> addMessage({
    required String message,
    required String role,
  }) async {
    final result = await repository.addMessage(
      conversationId: conversationId,
      message: message,
      role: role,
    );
    await loadMessages();
    return result;
  }
}

final chatbotMessagesProvider = StateNotifierProvider.family<
    ChatbotMessagesNotifier,
    ChatbotMessagesState,
    String>((ref, conversationId) {
  final repository = ref.watch(chatbotRepositoryProvider);
  final notifier = ChatbotMessagesNotifier(
    repository: repository,
    conversationId: conversationId,
  );
  notifier.loadMessages();
  return notifier;
});

// ============================================================
// DOCTOR PATIENTS PROVIDER
// ============================================================

class DoctorPatientOverview {
  final UserModel patient;
  final TreatmentModel? treatment;
  final double adherencePercentage;
  final DateTime? lastUpdatedAt;

  const DoctorPatientOverview({
    required this.patient,
    required this.treatment,
    required this.adherencePercentage,
    required this.lastUpdatedAt,
  });

  String get phase => treatment?.phase ?? 'unknown';

  String get statusLabel {
    if (adherencePercentage >= 80) return 'good';
    if (adherencePercentage >= 60) return 'warning';
    return 'critical';
  }
}

class DoctorPatientsState {
  final bool isLoading;
  final List<DoctorPatientOverview> patients;
  final String? error;

  const DoctorPatientsState({
    this.isLoading = false,
    this.patients = const [],
    this.error,
  });

  DoctorPatientsState copyWith({
    bool? isLoading,
    List<DoctorPatientOverview>? patients,
    String? error,
  }) {
    return DoctorPatientsState(
      isLoading: isLoading ?? this.isLoading,
      patients: patients ?? this.patients,
      error: error ?? this.error,
    );
  }
}

class DoctorPatientsNotifier extends StateNotifier<DoctorPatientsState> {
  final UserRepository userRepository;
  final TreatmentRepository treatmentRepository;
  final String doctorId;

  DoctorPatientsNotifier({
    required this.userRepository,
    required this.treatmentRepository,
    required this.doctorId,
  }) : super(const DoctorPatientsState());

  Future<void> loadPatients() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final patients = await userRepository.getPatients(doctorId);
      final treatments = await treatmentRepository.getDoctorPatientsTreatments(
        doctorId,
      );

      final treatmentByPatientId = <String, TreatmentModel>{};
      for (final treatment in treatments) {
        treatmentByPatientId[treatment.patientId] = treatment;
      }

      final overviews = patients.map((patient) {
        final treatment = treatmentByPatientId[patient.id];
        return DoctorPatientOverview(
          patient: patient,
          treatment: treatment,
          adherencePercentage: treatment?.adherencePercentage ?? 0.0,
          lastUpdatedAt: treatment?.updatedAt ?? patient.updatedAt,
        );
      }).toList();

      state = state.copyWith(isLoading: false, patients: overviews);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final doctorPatientsProvider = StateNotifierProvider.family<
    DoctorPatientsNotifier, DoctorPatientsState, String>((ref, doctorId) {
  final userRepository = ref.watch(userRepositoryProvider);
  final treatmentRepository = ref.watch(treatmentRepositoryProvider);
  final notifier = DoctorPatientsNotifier(
    userRepository: userRepository,
    treatmentRepository: treatmentRepository,
    doctorId: doctorId,
  );
  notifier.loadPatients();
  return notifier;
});

// ============================================================
// DOCTOR ALERTS PROVIDER
// ============================================================

class DoctorAlertsState {
  final bool isLoading;
  final List<AlertModel> alerts;
  final String? error;

  const DoctorAlertsState({
    this.isLoading = false,
    this.alerts = const [],
    this.error,
  });

  DoctorAlertsState copyWith({
    bool? isLoading,
    List<AlertModel>? alerts,
    String? error,
  }) {
    return DoctorAlertsState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      error: error ?? this.error,
    );
  }
}

class DoctorAlertsNotifier extends StateNotifier<DoctorAlertsState> {
  final AlertRepository repository;
  final SupabaseClient client;
  final String doctorId;
  StreamSubscription<List<Map<String, dynamic>>>? _alertsSubscription;

  DoctorAlertsNotifier({
    required this.repository,
    required this.client,
    required this.doctorId,
  }) : super(const DoctorAlertsState()) {
    _subscribeRealtime();
    _reconnectSubscription = ConnectivityService.instance.onReconnect.listen((_) {
      _subscribeRealtime();
      loadAlerts();
    });
  }

  StreamSubscription<void>? _reconnectSubscription;

  void _subscribeRealtime() {
    _alertsSubscription?.cancel();
    _alertsSubscription = client
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('doctor_id', doctorId)
        .listen((rows) {
          final alerts = rows.map(AlertModel.fromJson).toList();
          state = state.copyWith(alerts: alerts, isLoading: false, error: null);
        });
  }

  Future<void> loadAlerts() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final alerts = await repository.getDoctorAlerts(doctorId);
      state = state.copyWith(isLoading: false, alerts: alerts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsResolved(String alertId) async {
    try {
      await repository.updateAlert(
        alertId: alertId,
        isRead: true,
        actionTaken: true,
      );
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    _reconnectSubscription?.cancel();
    super.dispose();
  }
}

final doctorAlertsProvider = StateNotifierProvider.family<DoctorAlertsNotifier,
    DoctorAlertsState, String>((ref, doctorId) {
  final repository = ref.watch(alertRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final notifier = DoctorAlertsNotifier(
    repository: repository,
    client: client,
    doctorId: doctorId,
  );
  notifier.loadAlerts();
  return notifier;
});
