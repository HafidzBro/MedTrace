import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtrace/core/error/auth_error_mapper.dart';
import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/chatbot_conversation_model.dart';
import 'package:medtrace/data/models/chatbot_log_model.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/services/device_location_service.dart';
import 'package:medtrace/services/notification_preference_service.dart';
import 'package:medtrace/services/pending_patient_registration_service.dart';
import 'package:medtrace/services/supabase/dashboard_service.dart';
import 'package:medtrace/services/supabase/medication_service.dart';
import 'package:medtrace/services/supabase_service.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Supabase Service Provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client: client);
});

final currentPatientDashboardSummaryProvider =
    FutureProvider<PatientDashboardSummary>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    throw StateError('No authenticated patient profile is available.');
  }

  final service = ref.watch(supabaseServiceProvider);
  return service.dashboard.patientSummary(user.id);
});

final currentDoctorDashboardSummaryProvider =
    FutureProvider<DoctorDashboardSummary>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    throw StateError('No authenticated doctor profile is available.');
  }

  final service = ref.watch(supabaseServiceProvider);
  return service.dashboard.doctorSummary(user.id);
});

final currentPatientIntakePlanProvider =
    FutureProvider<MedicationIntakePlan?>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    throw StateError('No authenticated patient profile is available.');
  }

  final service = ref.watch(supabaseServiceProvider);
  return service.currentPatientIntakePlan(user.id);
});

final currentPatientAdherenceHistoryProvider =
    FutureProvider<List<MedicationLogModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    throw StateError('No authenticated patient profile is available.');
  }

  final service = ref.watch(supabaseServiceProvider);
  return service.patientAdherenceHistory(user.id);
});

final currentPatientProfileSummaryProvider =
    FutureProvider<PatientProfileSummary>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    throw StateError('No authenticated patient profile is available.');
  }

  final service = ref.watch(supabaseServiceProvider);
  return service.patientProfileSummary(user.id);
});

final pendingPatientRegistrationServiceProvider =
    Provider<PendingPatientRegistrationService>((ref) {
  return const PendingPatientRegistrationService();
});

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return const DeviceLocationService();
});

final notificationPreferenceServiceProvider =
    Provider<NotificationPreferenceService>((ref) {
  return const NotificationPreferenceService();
});

final currentPatientNotificationEnabledProvider =
    FutureProvider<bool>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return true;

  final service = ref.watch(notificationPreferenceServiceProvider);
  return service.isMedicationNotificationEnabled(user.id);
});

class PatientChatbotState {
  final bool isLoading;
  final bool isSending;
  final ChatbotConversation? conversation;
  final List<ChatbotLogModel> messages;
  final String? error;

  const PatientChatbotState({
    this.isLoading = false,
    this.isSending = false,
    this.conversation,
    this.messages = const [],
    this.error,
  });

  PatientChatbotState copyWith({
    bool? isLoading,
    bool? isSending,
    Object? conversation = _unset,
    List<ChatbotLogModel>? messages,
    Object? error = _unset,
  }) {
    return PatientChatbotState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      conversation: identical(conversation, _unset)
          ? this.conversation
          : conversation as ChatbotConversation?,
      messages: messages ?? this.messages,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class PatientChatbotNotifier extends StateNotifier<PatientChatbotState> {
  final SupabaseService supabaseService;
  final String patientId;

  PatientChatbotNotifier({
    required this.supabaseService,
    required this.patientId,
  }) : super(const PatientChatbotState());

  Future<void> load() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final conversation =
          await supabaseService.chatbot.latestConversation(patientId);
      final messages = conversation == null
          ? <ChatbotLogModel>[]
          : await supabaseService.chatbot.listLogs(conversation.id);
      state = state.copyWith(
        isLoading: false,
        conversation: conversation,
        messages: messages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> send(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || state.isSending) return;

    try {
      state = state.copyWith(isSending: true, error: null);
      final result = await supabaseService.chatbot.sendPatientMessage(
        patientId: patientId,
        message: trimmed,
      );
      state = state.copyWith(
        isSending: false,
        conversation: result.conversation,
        messages: result.logs,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }
}

final currentPatientChatbotProvider = StateNotifierProvider.autoDispose<
    PatientChatbotNotifier, PatientChatbotState>((ref) {
  final user = ref.watch(authProvider).user;
  final service = ref.watch(supabaseServiceProvider);
  if (user == null) {
    throw StateError('No authenticated patient profile is available.');
  }

  final notifier = PatientChatbotNotifier(
    supabaseService: service,
    patientId: user.id,
  );
  notifier.load();
  return notifier;
});

const _unset = Object();

// Auth State
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;
  final bool requiresEmailVerification;
  final String? pendingVerificationEmail;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
    this.requiresEmailVerification = false,
    this.pendingVerificationEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    Object? user = _unset,
    Object? error = _unset,
    bool? isAuthenticated,
    bool? requiresEmailVerification,
    Object? pendingVerificationEmail = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: identical(user, _unset) ? this.user : user as UserModel?,
      error: identical(error, _unset) ? this.error : error as String?,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      requiresEmailVerification:
          requiresEmailVerification ?? this.requiresEmailVerification,
      pendingVerificationEmail: identical(pendingVerificationEmail, _unset)
          ? this.pendingVerificationEmail
          : pendingVerificationEmail as String?,
    );
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService supabaseService;
  final PendingPatientRegistrationService pendingRegistrationService;

  AuthNotifier(
    this.supabaseService, {
    this.pendingRegistrationService = const PendingPatientRegistrationService(),
  }) : super(AuthState());

  Future<void> checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true);
      final user = supabaseService.client.auth.currentUser;

      if (user != null) {
        final userModel = await supabaseService.getUser(user.id);
        state = state.copyWith(
          isAuthenticated: true,
          user: userModel,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> register({
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
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedDoctorCode = doctorCode.trim().toUpperCase();

      state = state.copyWith(
        isLoading: true,
        error: null,
        requiresEmailVerification: false,
        pendingVerificationEmail: null,
      );

      await supabaseService.registerPatient(
        email: normalizedEmail,
        password: password,
        doctorCode: normalizedDoctorCode,
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

      await supabaseService.logout();
      state = state.copyWith(
        isAuthenticated: false,
        user: null,
        isLoading: false,
      );
      return true;
    } on EmailVerificationRequiredException catch (e) {
      await pendingRegistrationService.save(
        PendingPatientRegistration(
          email: e.email,
          fullName: fullName.trim(),
          doctorCode: doctorCode.trim().toUpperCase(),
          dateOfBirth: dateOfBirth,
          nik: nik?.trim().isEmpty == true ? null : nik?.trim(),
          diagnosisDate: diagnosisDate,
          tbCaseCategory: tbCaseCategory?.trim().isEmpty == true
              ? null
              : tbCaseCategory?.trim(),
          tbCaseDescription: tbCaseDescription?.trim().isEmpty == true
              ? null
              : tbCaseDescription?.trim(),
          phoneNumber:
              phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
          gender: gender?.trim().isEmpty == true ? null : gender?.trim(),
          address: address?.trim().isEmpty == true ? null : address?.trim(),
          latitude: latitude,
          longitude: longitude,
          locationAccuracy: locationAccuracy,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        requiresEmailVerification: true,
        pendingVerificationEmail: e.email,
        error: mapAuthErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: mapAuthErrorMessage(e), isLoading: false);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      state = state.copyWith(
        isLoading: true,
        error: null,
        requiresEmailVerification: false,
        pendingVerificationEmail: null,
      );

      final user = await supabaseService.loginUser(
        email: normalizedEmail,
        password: password,
      );

      await pendingRegistrationService.deleteForEmail(normalizedEmail);
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      UserModel? completedUser;
      try {
        completedUser =
            await _tryCompletePendingRegistration(email.trim().toLowerCase());
      } catch (completionError) {
        state = state.copyWith(
          error: mapAuthErrorMessage(completionError),
          isLoading: false,
        );
        return false;
      }
      if (completedUser != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: completedUser,
          isLoading: false,
          error: null,
        );
        return true;
      }
      state = state.copyWith(error: mapAuthErrorMessage(e), isLoading: false);
      return false;
    }
  }

  Future<bool> resendVerificationEmail([String? email]) async {
    final targetEmail = email ?? state.pendingVerificationEmail;
    if (targetEmail == null || targetEmail.trim().isEmpty) {
      state = state.copyWith(
        error: 'Email verifikasi belum tersedia. Ulangi registrasi pasien.',
      );
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      await supabaseService.resendPatientVerificationEmail(targetEmail);
      state = state.copyWith(
        isLoading: false,
        requiresEmailVerification: true,
        pendingVerificationEmail: targetEmail.trim().toLowerCase(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: mapAuthErrorMessage(e), isLoading: false);
      return false;
    }
  }

  Future<UserModel?> _tryCompletePendingRegistration(String email) async {
    final authUser = supabaseService.client.auth.currentUser;
    if (authUser == null) return null;

    final pending = await pendingRegistrationService.readForEmail(email);
    if (pending == null) return null;

    final user =
        await supabaseService.completePatientRegistrationAfterVerification(
      userId: authUser.id,
      email: pending.email,
      fullName: pending.fullName,
      doctorCode: pending.doctorCode,
      dateOfBirth: pending.dateOfBirth,
      nik: pending.nik,
      diagnosisDate: pending.diagnosisDate,
      tbCaseCategory: pending.tbCaseCategory,
      tbCaseDescription: pending.tbCaseDescription,
      phoneNumber: pending.phoneNumber,
      gender: pending.gender,
      address: pending.address,
      latitude: pending.latitude,
      longitude: pending.longitude,
      locationAccuracy: pending.locationAccuracy,
    );

    await pendingRegistrationService.deleteForEmail(email);
    return user;
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true);
      await supabaseService.logout();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final pendingRegistrationService =
      ref.watch(pendingPatientRegistrationServiceProvider);
  final notifier = AuthNotifier(
    supabaseService,
    pendingRegistrationService: pendingRegistrationService,
  );
  notifier.checkAuthStatus();
  return notifier;
});

// Theme Provider
final appThemeProvider = Provider<AppTheme>((ref) {
  final user = ref.watch(authProvider).user;
  if (user?.isDoctor ?? false) {
    return AppTheme.doctor();
  }
  return AppTheme.patient();
});

// Doctor Code Validation State
class DoctorCodeState {
  final bool isValidating;
  final bool isValid;
  final String? error;
  final DoctorCodeModel? code;

  DoctorCodeState({
    this.isValidating = false,
    this.isValid = false,
    this.error,
    this.code,
  });

  DoctorCodeState copyWith({
    bool? isValidating,
    bool? isValid,
    Object? error = _unset,
    DoctorCodeModel? code,
  }) {
    return DoctorCodeState(
      isValidating: isValidating ?? this.isValidating,
      isValid: isValid ?? this.isValid,
      error: identical(error, _unset) ? this.error : error as String?,
      code: code ?? this.code,
    );
  }
}

// Doctor Code Notifier
class DoctorCodeNotifier extends StateNotifier<DoctorCodeState> {
  final SupabaseService supabaseService;

  DoctorCodeNotifier(this.supabaseService) : super(DoctorCodeState());

  Future<void> validateCode(String code) async {
    try {
      state = state.copyWith(isValidating: true, error: null);

      final validatedCode = await supabaseService.validateDoctorCode(code);

      state = state.copyWith(
        isValid: validatedCode.canBeUsed,
        code: validatedCode,
        isValidating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isValid: false,
        error: mapAuthErrorMessage(e),
        isValidating: false,
      );
    }
  }

  void reset() {
    state = DoctorCodeState();
  }
}

// Doctor Code Provider
final doctorCodeProvider =
    StateNotifierProvider<DoctorCodeNotifier, DoctorCodeState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return DoctorCodeNotifier(supabaseService);
});
