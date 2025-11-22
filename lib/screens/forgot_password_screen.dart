import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.forgotPassword(
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message.isNotEmpty 
              ? response.message 
              : 'OTP has been sent to your email address',
        );
        
        // Navigate to OTP verification screen
        NavigationUtils.push(
          context,
          OtpVerificationScreen(
            email: _emailController.text.trim(),
            mobile: _mobileController.text.trim(),
          ),
        );
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error sending OTP: ${e.toString()}',
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
        title: "Forgot Password",
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
                Icons.lock_reset,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
              
              Text(
                'Forgot Password?',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Enter your email address and mobile number to receive an OTP',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
              
              // Email Field
              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hintText: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email address is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              
              // Mobile Field
              CustomTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                hintText: 'Enter your mobile number',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
              
              // Send OTP Button
              CustomButton(
                text: 'Send OTP',
                onPressed: _isLoading ? null : _sendOtp,
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

