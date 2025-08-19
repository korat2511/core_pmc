import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final ButtonType buttonType;
  final double? width;
  final double? height;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.buttonType = ButtonType.primary,
    this.width,
    this.height,
    this.prefixIcon,
    this.suffixIcon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? (ResponsiveUtils.isMobile(context) ? double.infinity : 400),
      height: height ?? ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 48,
        tablet: 52,
        desktop: 56,
      ),
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getTextColor(),
          elevation: _getElevation(),
          shadowColor: AppColors.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 24,
              tablet: 28,
              desktop: 32,
            ),
            vertical: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
          ),
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
            child: CircularProgressIndicator(
              color: _getTextColor(),
              strokeWidth: 2,
            ),
          ),
          SizedBox(
            width: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          Text(
            'Loading...',
            style: _getTextStyle(context),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          prefixIcon!,
          SizedBox(
            width: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
        ],
        Flexible(
          child: Text(
            text,
            style: _getTextStyle(context),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (suffixIcon != null) ...[
          SizedBox(
            width: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          suffixIcon!,
        ],
      ],
    );
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    
    if (!isEnabled) return AppColors.textLight;
    
    switch (buttonType) {
      case ButtonType.primary:
        return AppColors.primary;
      case ButtonType.secondary:
        return AppColors.secondaryColor;
      case ButtonType.success:
        return AppColors.successColor;
      case ButtonType.error:
        return AppColors.errorColor;
      case ButtonType.warning:
        return AppColors.warningColor;
      case ButtonType.info:
        return AppColors.infoColor;
      case ButtonType.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    
    if (!isEnabled) return AppColors.textSecondary;
    
    switch (buttonType) {
      case ButtonType.primary:
      case ButtonType.secondary:
      case ButtonType.success:
      case ButtonType.error:
      case ButtonType.warning:
      case ButtonType.info:
        return AppColors.textWhite;
      case ButtonType.outline:
        return AppColors.primaryColor;
    }
  }

  double _getElevation() {
    if (!isEnabled) return 0;
    
    switch (buttonType) {
      case ButtonType.primary:
      case ButtonType.secondary:
      case ButtonType.success:
      case ButtonType.error:
      case ButtonType.warning:
      case ButtonType.info:
        return 4;
      case ButtonType.outline:
        return 0;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    return AppTypography.labelLarge.copyWith(
      fontSize: ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 16,
        tablet: 18,
        desktop: 20,
      ),
      color: _getTextColor(),
      fontWeight: FontWeight.w600,
    );
  }
}

enum ButtonType {
  primary,
  secondary,
  success,
  error,
  warning,
  info,
  outline,
} 