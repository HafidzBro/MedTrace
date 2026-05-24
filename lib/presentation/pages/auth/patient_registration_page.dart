import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

enum _RegistrationStep { identity, medical, treatment, confirmation }

enum _ConfirmationMode { completed, verificationRequired }

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
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _doctorCodeController;

  _RegistrationStep _step = _RegistrationStep.identity;
  _ConfirmationMode _confirmationMode = _ConfirmationMode.completed;
  String? _selectedGender = 'female';
  DateTime? _dateOfBirth;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _doctorCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _doctorCodeController.dispose();
    super.dispose();
  }

  int get _stepIndex => _RegistrationStep.values.indexOf(_step);

  void _handleBack() {
    if (_step == _RegistrationStep.confirmation) {
      context.go(AppRoutes.login);
      return;
    }

    if (_stepIndex > 0) {
      setState(() {
        _step = _RegistrationStep.values[_stepIndex - 1];
      });
      return;
    }

    context.pop();
  }

  Future<void> _handleContinue() async {
    if (_step == _RegistrationStep.identity) {
      if (_identityFormKey.currentState?.validate() != true) return;
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match', isError: true);
        return;
      }
      setState(() => _step = _RegistrationStep.medical);
      return;
    }

    if (_step == _RegistrationStep.medical) {
      if (_medicalFormKey.currentState?.validate() != true) return;
      setState(() => _step = _RegistrationStep.treatment);
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
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          gender: _selectedGender,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (success) {
      setState(() {
        _confirmationMode = _ConfirmationMode.completed;
        _step = _RegistrationStep.confirmation;
      });
      return;
    }

    if (authState.requiresEmailVerification) {
      setState(() {
        _confirmationMode = _ConfirmationMode.verificationRequired;
        _step = _RegistrationStep.confirmation;
      });
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

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    final success = await ref
        .read(authProvider.notifier)
        .resendVerificationEmail(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isResending = false);
    _showSnackBar(
      success ? 'Verification link sent again.' : ref.read(authProvider).error!,
      isError: !success,
    );
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

    if (_step == _RegistrationStep.confirmation) {
      return _RegistrationConfirmation(
        mode: _confirmationMode,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        isBusy: authState.isLoading || _isResending,
        onResend: _resendVerification,
        onLogin: () => context.go(AppRoutes.login),
        onDashboard: () => context.go(AppRoutes.patientDashboard),
      );
    }

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
      case _RegistrationStep.identity:
        return 'Patient Identity';
      case _RegistrationStep.medical:
        return 'Medical & Location';
      case _RegistrationStep.treatment:
        return 'Treatment Setup';
      case _RegistrationStep.confirmation:
        return 'Confirmation';
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _RegistrationStep.identity:
        return _IdentityStep(
          key: const ValueKey('identity-step'),
          formKey: _identityFormKey,
          fullNameController: _fullNameController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
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
      case _RegistrationStep.medical:
        return _MedicalStep(
          key: const ValueKey('medical-step'),
          formKey: _medicalFormKey,
          addressController: _addressController,
        );
      case _RegistrationStep.treatment:
        return _TreatmentStep(
          key: const ValueKey('treatment-step'),
          formKey: _treatmentFormKey,
          doctorCodeController: _doctorCodeController,
        );
      case _RegistrationStep.confirmation:
        return const SizedBox.shrink();
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

class _IdentityStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final String? selectedGender;
  final DateTime? dateOfBirth;
  final bool showPassword;
  final bool showConfirmPassword;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onPickDateOfBirth;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const _IdentityStep({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.selectedGender,
    required this.dateOfBirth,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onGenderChanged,
    required this.onPickDateOfBirth,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Details', style: AppTypography.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Provide the patient identity details used for their monitoring account.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 22),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _TextInput(
              controller: fullNameController,
              label: 'Full Name (Legal)',
              hint: 'e.g. Sarah Jenkins',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _TextInput(
              controller: emailController,
              label: 'Email',
              hint: 'example@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.trim().isValidEmail) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _TextInput(
              controller: passwordController,
              label: 'Password',
              hint: 'Minimum 6 characters',
              icon: Icons.lock_outline,
              obscureText: !showPassword,
              suffixIcon: IconButton(
                tooltip: showPassword ? 'Hide password' : 'Show password',
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if (value == null || !value.isValidPassword) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _TextInput(
              controller: confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Repeat password',
              icon: Icons.lock_reset_outlined,
              obscureText: !showConfirmPassword,
              suffixIcon: IconButton(
                tooltip: showConfirmPassword
                    ? 'Hide confirm password'
                    : 'Show confirm password',
                onPressed: onToggleConfirmPassword,
                icon: Icon(
                  showConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text('Biological Gender', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            _GenderSelector(
              value: selectedGender,
              onChanged: onGenderChanged,
            ),
            const SizedBox(height: 18),
            const Text('Date of Birth', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            _PickerField(
              icon: Icons.calendar_today_outlined,
              text: dateOfBirth == null
                  ? 'mm/dd/yyyy'
                  : _formatDate(dateOfBirth!),
              isPlaceholder: dateOfBirth == null,
              onTap: onPickDateOfBirth,
            ),
            const SizedBox(height: 18),
            _TextInput(
              controller: phoneController,
              label: 'Primary Phone Number',
              hint: '+1 (555) 000-0000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _MedicalStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;

  const _MedicalStep({
    super.key,
    required this.formKey,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medical Information', style: AppTypography.headline4),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 24),
          const _FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReadonlyField(
                  label: 'Diagnosis Date',
                  value: 'Managed by assigned doctor',
                  icon: Icons.calendar_month_outlined,
                ),
                SizedBox(height: 16),
                _ReadonlyField(
                  label: 'TB Case Category',
                  value: 'Managed by assigned doctor',
                  icon: Icons.medical_information_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Location Details', style: AppTypography.headline4),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TextInput(
                  controller: addressController,
                  label: 'Residential Address',
                  hint: 'Enter street address, landmark, or local area details',
                  icon: Icons.location_on_outlined,
                  minLines: 3,
                  maxLines: 4,
                ),
                const SizedBox(height: 18),
                Container(
                  height: 126,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFE6EAEA),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Color(0xFF00565A),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Location set later',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Precise location permission will be requested only when the map feature is implemented.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatmentStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController doctorCodeController;

  const _TreatmentStep({
    super.key,
    required this.formKey,
    required this.doctorCodeController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Treatment Setup',
                  style: AppTypography.headline4.copyWith(
                    color: const Color(0xFF004C4F),
                  ),
                ),
              ),
              Text(
                'Step 3 of 3',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              minHeight: 5,
              value: 1,
              backgroundColor: Color(0xFFE1E7E7),
              valueColor: AlwaysStoppedAnimation(Color(0xFF00565A)),
            ),
          ),
          const SizedBox(height: 26),
          const Text('Initial Therapy Status', style: AppTypography.bodyMedium),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _StatusOption(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Registered',
                  selected: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatusOption(
                  icon: Icons.medication_outlined,
                  label: 'Doctor sets therapy',
                  selected: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 38),
          _FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      color: Color(0xFF00565A),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Doctor Code', style: AppTypography.bodyMedium),
                  ],
                ),
                const SizedBox(height: 14),
                _TextInput(
                  controller: doctorCodeController,
                  label: '',
                  hint: 'Input code here...',
                  icon: Icons.key_outlined,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || !value.trim().isValidDoctorCode) {
                      return 'Enter a valid 6-character doctor code';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _InfoPanel(
            title: 'Intake Schedule',
            body:
                'Frequency, scheduled days, and medication details will be loaded from Supabase after the assigned doctor creates the treatment plan.',
          ),
        ],
      ),
    );
  }
}

class _RegistrationConfirmation extends StatelessWidget {
  final _ConfirmationMode mode;
  final String email;
  final String fullName;
  final bool isBusy;
  final VoidCallback onResend;
  final VoidCallback onLogin;
  final VoidCallback onDashboard;

  const _RegistrationConfirmation({
    required this.mode,
    required this.email,
    required this.fullName,
    required this.isBusy,
    required this.onResend,
    required this.onLogin,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final needsVerification = mode == _ConfirmationMode.verificationRequired;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  border: Border.all(color: const Color(0xFFE1E7E7), width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x336DEFD6),
                      blurRadius: 36,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.black,
                    child: Icon(
                      needsVerification ? Icons.mail_outline : Icons.check,
                      color: AppColors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                needsVerification
                    ? 'Verify Your Email'
                    : 'Registration Complete',
                textAlign: TextAlign.center,
                style: AppTypography.headline4.copyWith(
                  color: AppColors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                needsVerification
                    ? 'We sent a Supabase verification link to $email. Confirm it, then log in with the same patient account.'
                    : '${fullName.isEmpty ? 'Patient' : fullName} is now connected to the assigned doctor.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              if (needsVerification)
                _ActionButton(
                  label: 'Resend Verification Link',
                  icon: Icons.mark_email_unread_outlined,
                  isBusy: isBusy,
                  onPressed: onResend,
                )
              else
                _ActionButton(
                  label: 'Go to Dashboard',
                  icon: Icons.check_circle_outline,
                  isBusy: isBusy,
                  onPressed: onDashboard,
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isBusy ? null : onLogin,
                child: Text(
                  needsVerification ? 'Back to Login' : 'Return to Login',
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final _RegistrationStep currentStep;
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
          if (currentStep != _RegistrationStep.identity) ...[
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
            flex: currentStep == _RegistrationStep.identity ? 1 : 2,
            child: _ActionButton(
              label: currentStep == _RegistrationStep.identity
                  ? 'Continue to Medical History'
                  : currentStep == _RegistrationStep.medical
                      ? 'Continue to Step 3'
                      : 'Complete Registration',
              icon: currentStep == _RegistrationStep.treatment
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isBusy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00565A),
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.white),
              ),
            )
          : Icon(icon, size: 20),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelLarge.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E7E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;

  const _TextInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLength: maxLength,
      minLines: obscureText ? 1 : minLines,
      maxLines: obscureText ? 1 : maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF90A0A0), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFCFC),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFBFCBCB)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF00565A), width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.errorRed, width: 1.4),
        ),
      ),
    );

    if (label.isEmpty) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GenderSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('female', 'Female'),
      ('male', 'Male'),
      ('other', 'Other'),
    ];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8DFDF)),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(2),
                  onTap: () => onChanged(option.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == option.$1
                          ? AppColors.white
                          : Colors.transparent,
                      border: value == option.$1
                          ? Border.all(color: const Color(0xFFE1E7E7))
                          : null,
                    ),
                    child: Text(
                      option.$2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF004C4F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.text,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFC),
          border: Border.all(color: const Color(0xFFBFCBCB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF90A0A0), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      isPlaceholder ? AppColors.mediumGrey : AppColors.darkGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFCFC),
            border: Border.all(color: const Color(0xFFBFCBCB)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6F777A), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _StatusOption({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE9FFFA) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF00565A) : const Color(0xFFD8DFDF),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00565A), size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF004C4F),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String body;

  const _InfoPanel({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCFEFEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                color: Color(0xFF00565A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF00565A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mediumGrey,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
