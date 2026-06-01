import 'package:flutter/material.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_widgets.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class PatientRegistrationStep1Identity extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController nikController;
  final TextEditingController phoneController;
  final String? selectedGender;
  final DateTime? dateOfBirth;
  final bool showPassword;
  final bool showConfirmPassword;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onPickDateOfBirth;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const PatientRegistrationStep1Identity({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nikController,
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
    return RegistrationFormCard(
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
            RegistrationTextInput(
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
            RegistrationTextInput(
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
            RegistrationTextInput(
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
            RegistrationTextInput(
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
            RegistrationTextInput(
              controller: nikController,
              label: 'National Identity Number',
              hint: '16-digit NIK',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              maxLength: 16,
              validator: (value) {
                final nik = value?.trim() ?? '';
                if (nik.isEmpty) {
                  return 'National identity number is required';
                }
                if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
                  return 'NIK must be 16 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text('Biological Gender', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            RegistrationGenderSelector(
              value: selectedGender,
              onChanged: onGenderChanged,
            ),
            const SizedBox(height: 18),
            const Text('Date of Birth', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            RegistrationPickerField(
              icon: Icons.calendar_today_outlined,
              text: dateOfBirth == null
                  ? 'mm/dd/yyyy'
                  : _formatDate(dateOfBirth!),
              isPlaceholder: dateOfBirth == null,
              onTap: onPickDateOfBirth,
            ),
            const SizedBox(height: 18),
            RegistrationTextInput(
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
