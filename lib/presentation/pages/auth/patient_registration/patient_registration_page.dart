import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_step1_identity.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_step2_medical.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_step3_treatment.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/services/device_location_service.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

enum PatientRegistrationStep { identity, medical, treatment }

class PatientRegistrationPage extends ConsumerStatefulWidget {
  const PatientRegistrationPage({super.key});

  @override
  ConsumerState<PatientRegistrationPage> createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState
    extends ConsumerState<PatientRegistrationPage> {
  final _identityFormKey = GlobalKey<FormState>();
  final _medicalFormKey = GlobalKey<FormState>();
  final _treatmentFormKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _nikController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _doctorCodeController;
  late final TextEditingController _tbCaseDescriptionController;

  PatientRegistrationStep _step = PatientRegistrationStep.identity;
  String? _selectedGender = 'female';
  String _therapyStatus = 'registered';
  final Set<int> _selectedScheduleDays = {1, 2, 3, 4, 5};
  DateTime? _dateOfBirth;
  DateTime? _diagnosisDate;
  String? _tbCaseCategory = 'new_case';
  double? _latitude;
  double? _longitude;
  double? _locationAccuracy;
  bool _isLocating = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _nikController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _doctorCodeController = TextEditingController();
    _tbCaseDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _doctorCodeController.dispose();
    _tbCaseDescriptionController.dispose();
    super.dispose();
  }

  int get _stepIndex => PatientRegistrationStep.values.indexOf(_step);

  void _handleBack() {
    if (_stepIndex > 0) {
      setState(() {
        _step = PatientRegistrationStep.values[_stepIndex - 1];
      });
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.register);
  }

  Future<void> _handleContinue() async {
    if (_step == PatientRegistrationStep.identity) {
      if (_identityFormKey.currentState?.validate() != true) return;
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match', isError: true);
        return;
      }
      setState(() => _step = PatientRegistrationStep.medical);
      return;
    }

    if (_step == PatientRegistrationStep.medical) {
      if (_medicalFormKey.currentState?.validate() != true) return;
      setState(() => _step = PatientRegistrationStep.treatment);
      return;
    }

    await _submitRegistration();
  }

  Future<void> _submitRegistration() async {
    if (_treatmentFormKey.currentState?.validate() != true) return;

    final code = _doctorCodeController.text.trim().toUpperCase();
    await ref.read(doctorCodeProvider.notifier).validateCode(code);
    final codeState = ref.read(doctorCodeProvider);
    if (!codeState.isValid) {
      _showSnackBar(
        codeState.error ?? 'Invalid or expired doctor code',
        isError: true,
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          doctorCode: code,
          fullName: _fullNameController.text.trim(),
          dateOfBirth: _dateOfBirth,
          nik: _nikController.text.trim(),
          diagnosisDate: _diagnosisDate,
          tbCaseCategory: _tbCaseCategory,
          tbCaseDescription: _therapyStatus == 'on_treatment'
              ? _tbCaseDescriptionController.text.trim()
              : null,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          gender: _selectedGender,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          locationAccuracy: _locationAccuracy,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (success) {
      context.go(AppRoutes.patientDashboard);
      return;
    }

    if (authState.requiresEmailVerification) {
      _showSnackBar(
        authState.error ??
            'Patient account was created but requires email verification.',
        isError: true,
      );
      return;
    }

    _showSnackBar(authState.error ?? 'Registration failed', isError: true);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selected != null) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Future<void> _pickDiagnosisDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _diagnosisDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selected != null) {
      setState(() => _diagnosisDate = selected);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final location =
          await ref.read(deviceLocationServiceProvider).getCurrentLocation();
      if (!mounted) return;

      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _locationAccuracy = location.accuracy;
        if (location.address != null && location.address!.isNotEmpty) {
          _addressController.text = location.address!;
        }
      });

      _showSnackBar('Current location captured');
    } on LocationServiceDisabledException {
      _showSnackBar('Please enable location services.', isError: true);
    } on LocationPermissionDeniedForeverException {
      _showSnackBar(
        'Location permission is permanently denied. Enable it from app settings.',
        isError: true,
      );
    } on LocationPermissionDeniedException {
      _showSnackBar('Location permission was denied.', isError: true);
    } catch (e) {
      _showSnackBar('Unable to get current location: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final codeState = ref.watch(doctorCodeProvider);
    final isBusy = authState.isLoading || codeState.isValidating;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00565A)),
          onPressed: isBusy ? null : _handleBack,
        ),
        title: Text(
          'Patient Registration',
          style: AppTypography.headline4.copyWith(
            color: const Color(0xFF004C4F),
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepHeader(
                      stepIndex: _stepIndex,
                      title: _stepTitle,
                    ),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildStepContent(),
                    ),
                  ],
                ),
              ),
            ),
            _BottomActions(
              currentStep: _step,
              isBusy: isBusy,
              onBack: _handleBack,
              onContinue: _handleContinue,
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case PatientRegistrationStep.identity:
        return 'Patient Identity';
      case PatientRegistrationStep.medical:
        return 'Medical & Location';
      case PatientRegistrationStep.treatment:
        return 'Treatment Setup';
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case PatientRegistrationStep.identity:
        return PatientRegistrationStep1Identity(
          key: const ValueKey('identity-step'),
          formKey: _identityFormKey,
          fullNameController: _fullNameController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          nikController: _nikController,
          phoneController: _phoneController,
          selectedGender: _selectedGender,
          dateOfBirth: _dateOfBirth,
          showPassword: _showPassword,
          showConfirmPassword: _showConfirmPassword,
          onGenderChanged: (value) => setState(() => _selectedGender = value),
          onPickDateOfBirth: _pickDateOfBirth,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onToggleConfirmPassword: () =>
              setState(() => _showConfirmPassword = !_showConfirmPassword),
        );
      case PatientRegistrationStep.medical:
        return PatientRegistrationStep2Medical(
          key: const ValueKey('medical-step'),
          formKey: _medicalFormKey,
          diagnosisDate: _diagnosisDate,
          tbCaseCategory: _tbCaseCategory,
          onPickDiagnosisDate: _pickDiagnosisDate,
          onTbCaseCategoryChanged: (value) {
            setState(() {
              _tbCaseCategory = value;
              _therapyStatus =
                  value == 'new_case' ? 'registered' : 'on_treatment';
              if (_therapyStatus == 'registered') {
                _tbCaseDescriptionController.clear();
              }
            });
          },
          addressController: _addressController,
          latitude: _latitude,
          longitude: _longitude,
          isLocating: _isLocating,
          onUseCurrentLocation: _useCurrentLocation,
        );
      case PatientRegistrationStep.treatment:
        return PatientRegistrationStep3Treatment(
          key: const ValueKey('treatment-step'),
          formKey: _treatmentFormKey,
          doctorCodeController: _doctorCodeController,
          tbCaseDescriptionController: _tbCaseDescriptionController,
          therapyStatus: _therapyStatus,
          isTherapyStatusLocked: true,
          selectedScheduleDays: _selectedScheduleDays,
          onTherapyStatusChanged: (value) {
            setState(() => _therapyStatus = value);
          },
          onScheduleDayToggled: (day) {
            setState(() {
              if (_selectedScheduleDays.contains(day)) {
                _selectedScheduleDays.remove(day);
              } else {
                _selectedScheduleDays.add(day);
              }
            });
          },
        );
    }
  }
}

class _StepHeader extends StatelessWidget {
  final int stepIndex;
  final String title;

  const _StepHeader({
    required this.stepIndex,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${stepIndex + 1} of 3',
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFF00565A),
                fontWeight: FontWeight.w600,
              ),
            ),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.darkGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (stepIndex + 1) / 3,
            backgroundColor: const Color(0xFFE1E7E7),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF00565A)),
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  final PatientRegistrationStep currentStep;
  final bool isBusy;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _BottomActions({
    required this.currentStep,
    required this.isBusy,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 16, 26, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9F9),
        border: Border(top: BorderSide(color: Color(0xFFE1E7E7))),
      ),
      child: Row(
        children: [
          if (currentStep != PatientRegistrationStep.identity) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: currentStep == PatientRegistrationStep.identity ? 1 : 2,
            child: RegistrationActionButton(
              label: currentStep == PatientRegistrationStep.identity
                  ? 'Continue to Medical History'
                  : currentStep == PatientRegistrationStep.medical
                      ? 'Continue to Step 3'
                      : 'Complete Registration',
              icon: currentStep == PatientRegistrationStep.treatment
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward,
              isBusy: isBusy,
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}
