import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/theme/app_typography.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'signup_next_step_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

            try {
        final result = await AuthService.login(
          mobile: _mobileController.text.trim(),
          password: _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success message
          SnackBarUtils.showSuccess(context, message: 'Login successful!');
          
          // Check if user has a company
          final currentUser = AuthService.currentUser;
          final hasCompany = currentUser?.company != null || 
                            (currentUser?.allowedCompanies != null && 
                             currentUser!.allowedCompanies!.isNotEmpty);
          
          if (hasCompany) {
            // User has a company, navigate to home
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            // User has no company, navigate to signup next step
            if (currentUser != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SignupNextStepScreen(
                    userData: {
                      'id': currentUser.id,
                      'first_name': currentUser.firstName,
                      'last_name': currentUser.lastName,
                      'email': currentUser.email,
                      'mobile': currentUser.mobile,
                    },
                  ),
                ),
              );
            } else {
              // Fallback to home if user data is not available
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        } else {
          // Show error message from API response
          SnackBarUtils.showError(
            context,
            message: result['message'],
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        SnackBarUtils.showError(
          context,
          message: 'Something went wrong. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: SafeArea(
                child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: GestureDetector(
            onTap: () {
              // Close keyboard when tapping outside
              FocusScope.of(context).unfocus();
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(
                      height: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 40,
                        tablet: 75,
                        desktop: 100,
                      ),
                    ),
                    // Logo Section
                    SizedBox(
                      width: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 170,
                        tablet: 180,
                        desktop: 220,
                      ),
                      height: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 100,
                        tablet: 120,
                        desktop: 140,
                      ),

                      child: Image.asset(
                        'assets/images/pmc.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Text(
                      'Welcome Back 👋',
                      style: AppTypography.headlineMedium,
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: 10),
                    // Note
                    Container(
                      padding: ResponsiveUtils.responsivePadding(context),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Please enter mobile number and password to access app',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 32,
                        tablet: 40,
                        desktop: 48,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 20,
                        tablet: 30,
                        desktop: 40,
                      ),
                    ),
                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Mobile Number Field
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
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 16,
                              tablet: 20,
                              desktop: 24,
                            ),
                          ),
                          // Password Field
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            maxLines: 1,
                            hintText: 'Enter your password',
                            obscureText: !_isPasswordVisible,

                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 32,
                              tablet: 40,
                              desktop: 48,
                            ),
                          ),
                          // Login Button
                          CustomButton(
                            text: 'Login',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            buttonType: ButtonType.primary,
                          ),
                          const SizedBox(height: 24),

                          // Signup Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacementNamed('/signup');
                                },
                                child: Text(
                                  'Sign Up',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Company Signup Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Want to create a company? ',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacementNamed('/company-signup');
                                },
                                child: Text(
                                  'Register Company',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.secondaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
