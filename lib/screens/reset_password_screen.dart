import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message.isNotEmpty 
              ? response.message 
              : 'Password reset successfully',
        );
        
        // Navigate back to login
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error resetting password: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Reset Password",
        showDrawer: false,
        showBackButton: true,
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
              
              Icon(
                Icons.lock_open,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
              
              Text(
                'Reset Your Password',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Enter your new password below',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
              
              // New Password Field
              CustomTextField(
                controller: _newPasswordController,
                label: 'New Password',
                hintText: 'Enter your new password',
                obscureText: !_isNewPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isNewPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'New password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              
              // Confirm Password Field
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                hintText: 'Re-enter your new password',
                obscureText: !_isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
              
              // Reset Password Button
              CustomButton(
                text: 'Reset Password',
                onPressed: _isLoading ? null : _resetPassword,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

