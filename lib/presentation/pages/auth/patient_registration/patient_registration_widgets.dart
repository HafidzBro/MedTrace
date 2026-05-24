import 'package:flutter/material.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class RegistrationFormCard extends StatelessWidget {
  final Widget child;

  const RegistrationFormCard({super.key, required this.child});

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

class RegistrationTextInput extends StatelessWidget {
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

  const RegistrationTextInput({
    super.key,
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

class RegistrationActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onPressed;

  const RegistrationActionButton({
    super.key,
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

class RegistrationGenderSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const RegistrationGenderSelector({
    super.key,
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

class RegistrationPickerField extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const RegistrationPickerField({
    super.key,
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

class RegistrationReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const RegistrationReadonlyField({
    super.key,
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
