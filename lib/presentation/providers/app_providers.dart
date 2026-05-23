import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtrace/services/supabase_service.dart';
import 'package:medtrace/shared/theme/app_theme.dart';
import 'package:medtrace/data/models/models.dart';

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Supabase Service Provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client: client);
});

// Auth State
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService supabaseService;

  AuthNotifier(this.supabaseService) : super(AuthState());

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
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await supabaseService.registerPatient(
        email: email,
        password: password,
        doctorCode: doctorCode,
        fullName: fullName,
      );

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await supabaseService.loginUser(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
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
  final notifier = AuthNotifier(supabaseService);
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
    String? error,
    DoctorCodeModel? code,
  }) {
    return DoctorCodeState(
      isValidating: isValidating ?? this.isValidating,
      isValid: isValid ?? this.isValid,
      error: error ?? this.error,
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
        error: e.toString(),
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
