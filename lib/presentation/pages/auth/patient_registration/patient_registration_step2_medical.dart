import 'package:flutter/material.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_widgets.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class PatientRegistrationStep2Medical extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;

  const PatientRegistrationStep2Medical({
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
          const RegistrationFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RegistrationReadonlyField(
                  label: 'Diagnosis Date',
                  value: 'Managed by assigned doctor',
                  icon: Icons.calendar_month_outlined,
                ),
                SizedBox(height: 16),
                RegistrationReadonlyField(
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
          RegistrationFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RegistrationTextInput(
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
