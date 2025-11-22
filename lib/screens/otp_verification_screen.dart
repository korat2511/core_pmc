import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String mobile;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.mobile,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    // Auto-focus first OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });
    
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        return true;
      }
      return false;
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    
    final otp = _getOtp();
    
    if (otp.length != 6) {
      SnackBarUtils.showError(
        context,
        message: 'Please enter the complete 6-digit OTP',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message.isNotEmpty 
              ? response.message 
              : 'OTP verified successfully',
        );
        
        // Navigate to reset password screen
        NavigationUtils.push(
          context,
          ResetPasswordScreen(
            email: widget.email,
            otp: otp,
          ),
        );
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Invalid OTP. Please try again',
        );
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error verifying OTP: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final response = await ApiService.forgotPassword(
        email: widget.email,
        mobile: widget.mobile,
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'OTP has been resent to your email address',
        );
        _startResendCountdown();
        
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error resending OTP: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Verify OTP",
        showDrawer: false,
        showBackButton: true,
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
            
            Icon(
              Icons.email_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
            
            Text(
              'Enter OTP',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'We\'ve sent a 6-digit OTP to\n${widget.email}',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 50,
                    tablet: 55,
                    desktop: 60,
                  ),
                  height: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 60,
                    tablet: 65,
                    desktop: 70,
                  ),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 20,
                        tablet: 26,
                        desktop: 28,
                      ),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onOtpChanged(index, value),
                  ),
                );
              }),
            ),
            
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
            
            // Verify Button
            CustomButton(
              text: 'Verify OTP',
              onPressed: _isLoading ? null : _verifyOtp,
              isLoading: _isLoading,
            ),
            
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            
            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Didn\'t receive OTP? ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_resendCountdown > 0)
                  Text(
                    'Resend in ${_resendCountdown}s',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _isResending ? null : _resendOtp,
                    child: Text(
                      'Resend OTP',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

