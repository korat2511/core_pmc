import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/date_picker_utils.dart';

class CustomDatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String format;
  final bool enabled;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  const CustomDatePickerField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.format = 'dd-MM-yyyy',
    this.enabled = true,
    this.validator,
    this.onTap,
    this.onChanged,
  });

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled) return;

    // Parse current date from controller if available
    DateTime? currentDate;
    if (controller.text.isNotEmpty) {
      currentDate = DatePickerUtils.parseDate(controller.text, format: format);
    }

    final String? selectedDate = await DatePickerUtils.pickDate(
      context: context,
      initialDate: currentDate ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      format: format,
    );

    if (selectedDate != null) {
      controller.text = selectedDate;
      onChanged?.call(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      validator: validator,
      onTap: onTap ?? () => _selectDate(context),
      onChanged: onChanged,
      style: AppTypography.bodyLarge.copyWith(
        color: enabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        hintText: hintText ?? 'Select $label',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        suffixIcon: Icon(
          Icons.calendar_today,
          color: enabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          size: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 20,
            tablet: 22,
            desktop: 24,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
          vertical: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
        ),
        filled: !enabled,
        fillColor: !enabled ? Theme.of(context).colorScheme.surface : null,
      ),
    );
  }
}
