import 'package:flutter/material.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_widgets.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class PatientRegistrationStep2Medical extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final DateTime? diagnosisDate;
  final String? tbCaseCategory;
  final VoidCallback onPickDiagnosisDate;
  final ValueChanged<String?> onTbCaseCategoryChanged;
  final TextEditingController addressController;
  final double? latitude;
  final double? longitude;
  final bool isLocating;
  final VoidCallback onUseCurrentLocation;

  const PatientRegistrationStep2Medical({
    super.key,
    required this.formKey,
    required this.diagnosisDate,
    required this.tbCaseCategory,
    required this.onPickDiagnosisDate,
    required this.onTbCaseCategoryChanged,
    required this.addressController,
    required this.latitude,
    required this.longitude,
    required this.isLocating,
    required this.onUseCurrentLocation,
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
          RegistrationFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Diagnosis Date', style: AppTypography.bodySmall),
                const SizedBox(height: 8),
                FormField<DateTime>(
                  initialValue: diagnosisDate,
                  validator: (_) {
                    if (diagnosisDate == null) {
                      return 'Diagnosis date is required';
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RegistrationPickerField(
                          icon: Icons.calendar_month_outlined,
                          text: diagnosisDate == null
                              ? 'Select diagnosis date'
                              : _formatDate(diagnosisDate!),
                          isPlaceholder: diagnosisDate == null,
                          onTap: onPickDiagnosisDate,
                        ),
                        if (field.hasError) ...[
                          const SizedBox(height: 6),
                          Text(
                            field.errorText!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.errorRed,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('TB Case Category', style: AppTypography.bodySmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tbCaseCategory,
                  isExpanded: true,
                  items: _tbCaseCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.value,
                          child: Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onTbCaseCategoryChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'TB case category is required';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.medical_information_outlined,
                      color: Color(0xFF90A0A0),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Color(0xFFFAFCFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Color(0xFFBFCBCB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide:
                          BorderSide(color: Color(0xFF00565A), width: 1.4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.errorRed),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide:
                          BorderSide(color: AppColors.errorRed, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const RegistrationReadonlyField(
                  label: 'TB Type',
                  value: 'Managed by assigned doctor',
                  icon: Icons.local_hospital_outlined,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: Color(0xFF00565A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasLocation
                                ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                                : 'Location not captured',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLocating ? null : onUseCurrentLocation,
                    icon: isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      hasLocation
                          ? 'Update Current Location'
                          : 'Use Current Location',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00565A),
                      side: const BorderSide(color: Color(0xFFBFCBCB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasLocation
                      ? 'This location will be saved as your current treatment location after registration.'
                      : 'Location permission will be requested to save your current treatment location.',
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

  bool get hasLocation => latitude != null && longitude != null;

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _TbCaseCategoryOption {
  final String value;
  final String label;

  const _TbCaseCategoryOption(this.value, this.label);
}

const _tbCaseCategories = [
  _TbCaseCategoryOption('new_case', 'New Case'),
  _TbCaseCategoryOption('relapse', 'Relapse'),
  _TbCaseCategoryOption('treatment_after_failure', 'Treatment After Failure'),
  _TbCaseCategoryOption(
    'treatment_after_loss_to_follow_up',
    'Treatment After Loss to Follow Up',
  ),
  _TbCaseCategoryOption('other', 'Other'),
];
