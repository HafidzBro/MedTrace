import 'package:flutter/material.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_widgets.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class PatientRegistrationStep3Treatment extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController doctorCodeController;
  final String therapyStatus;
  final Set<int> selectedScheduleDays;
  final ValueChanged<String> onTherapyStatusChanged;
  final ValueChanged<int> onScheduleDayToggled;

  const PatientRegistrationStep3Treatment({
    super.key,
    required this.formKey,
    required this.doctorCodeController,
    required this.therapyStatus,
    required this.selectedScheduleDays,
    required this.onTherapyStatusChanged,
    required this.onScheduleDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Initial Therapy Status', style: AppTypography.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatusOptionButton(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Registered',
                  selected: therapyStatus == 'registered',
                  onTap: () => onTherapyStatusChanged('registered'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatusOptionButton(
                  icon: Icons.medication_outlined,
                  label: 'On Treatment',
                  selected: therapyStatus == 'on_treatment',
                  onTap: () => onTherapyStatusChanged('on_treatment'),
                ),
              ),
            ],
          ),
          if (therapyStatus == 'on_treatment') ...[
            const SizedBox(height: 20),
            const _TreatmentDescriptionPanel(),
          ],
          const SizedBox(height: 32),
          RegistrationFormCard(
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
                RegistrationTextInput(
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
          _IntakeSchedulePanel(
            selectedDays: selectedScheduleDays,
            onDayToggled: onScheduleDayToggled,
          ),
        ],
      ),
    );
  }
}

class _StatusOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOptionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE9FFFA) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? const Color(0xFF00565A) : const Color(0xFFD8DFDF),
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (selected)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF00565A),
                    size: 18,
                  ),
                ),
              Center(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreatmentDescriptionPanel extends StatelessWidget {
  const _TreatmentDescriptionPanel();

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
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Color(0xFF00565A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Treatment Description',
                style: TextStyle(
                  color: Color(0xFF00565A),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'No treatment description is available yet. This section will show the real description from Supabase after the assigned doctor creates or updates the treatment plan.',
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

class _IntakeSchedulePanel extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onDayToggled;

  const _IntakeSchedulePanel({
    required this.selectedDays,
    required this.onDayToggled,
  });

  static const _days = [
    (1, 'M'),
    (2, 'T'),
    (3, 'W'),
    (4, 'T'),
    (5, 'F'),
    (6, 'S'),
    (7, 'S'),
  ];

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
          const Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: Color(0xFF00565A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Intake Schedule',
                style: TextStyle(
                  color: Color(0xFF00565A),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Scheduled Days',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in _days)
                _ScheduleDayChip(
                  label: day.$2,
                  selected: selectedDays.contains(day.$1),
                  onTap: () => onDayToggled(day.$1),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'This is a temporary reminder preference. It will be connected to the real reminder table when reminder CRUD is implemented.',
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

class _ScheduleDayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00565A) : AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBFCBCB)),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.white : AppColors.mediumGrey,
          ),
        ),
      ),
    );
  }
}
