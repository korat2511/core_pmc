import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(
          context,
          message: 'Session expired. Please login again.',
        );
        return;
      }

      final response = await ApiService.changePassword(
        apiToken: token,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message.isNotEmpty 
              ? response.message 
              : 'Password changed successfully',
        );
        NavigationUtils.pop(context, true);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to change password',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error changing password: ${e.toString()}',
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
        title: "Change Password",
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
              
              Text(
                'Change Your Password',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter your current password and choose a new one',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
              
              // Old Password Field
              CustomTextField(
                controller: _oldPasswordController,
                label: 'Current Password',
                hintText: 'Enter your current password',
                obscureText: !_isOldPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isOldPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isOldPasswordVisible = !_isOldPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Current password is required';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              
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
                  if (value == _oldPasswordController.text) {
                    return 'New password must be different from current password';
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
              
              // Change Password Button
              CustomButton(
                text: 'Change Password',
                onPressed: _isLoading ? null : _changePassword,
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

