import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/theme/app_typography.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'signup_next_step_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCodeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isValidatingCode = false;
  bool _companyCodeValidated = false;
  String? _companyName;

  @override
  void dispose() {
    _companyCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateCompanyCode() async {
    if (_companyCodeController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter company code');
      return;
    }

    setState(() {
      _isValidatingCode = true;
      _companyCodeValidated = false;
      _companyName = null;
    });

    try {
      final result = await ApiService.validateCompanyCode(
        companyCode: _companyCodeController.text.trim(),
      );

      setState(() {
        _isValidatingCode = false;
      });

      if (result['status'] == 1) {
        setState(() {
          _companyCodeValidated = true;
          _companyName = result['company']?['name'];
        });
        SnackBarUtils.showSuccess(context, message: 'Company code verified!');
      } else {
        SnackBarUtils.showError(
          context,
          message: result['message'] ?? 'Invalid company code',
        );
      }
    } catch (e) {
      setState(() {
        _isValidatingCode = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to validate company code',
      );
    }
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();
    
    final companyCode = _companyCodeController.text.trim();
    if (companyCode.isNotEmpty && !_companyCodeValidated) {
      SnackBarUtils.showError(
        context,
        message: 'Please validate company code first',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await ApiService.userSignup(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          companyCode: companyCode.isEmpty ? null : companyCode,
          designationId: null, // Will be set by admin later
        );

        setState(() {
          _isLoading = false;
        });

        if (result['status'] == 1) {
          final bool hasCompany = result['has_company'] == true;
          if (hasCompany) {
            SnackBarUtils.showSuccess(
              context,
              message: 'Account created successfully! Please login.',
            );
            Navigator.of(context).pushReplacementNamed('/login');
          } else {
            SnackBarUtils.showInfo(
              context,
              message: 'Account created! Complete your company setup to continue.',
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SignupNextStepScreen(
                  userData: Map<String, dynamic>.from(result['user'] ?? {}),
                ),
              ),
            );
          }
        } else {
          SnackBarUtils.showError(
            context,
            message: result['message'] ?? 'Signup failed',
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
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
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Section
                Center(
                  child: SizedBox(
                    width: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 140,
                      tablet: 160,
                      desktop: 200,
                    ),
                    height: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 80,
                      tablet: 100,
                      desktop: 120,
                    ),
                    child: Image.asset(
                      'assets/images/pmc_transparent_1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Create Account',
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
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
                    'Enter your company code if you have one now, or skip and create/join a company after signup.',
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
                const SizedBox(height: 32),

                // Signup Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Company Code Field with Validation
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _companyCodeController,
                              label: 'Company Code (optional)',
                              hintText: 'Enter company code',
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (value) {
                                setState(() {
                                  _companyCodeValidated = false;
                                  _companyName = null;
                                });
                              },
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return null;
                                }
                                if (!_companyCodeValidated) {
                                  return 'Please validate company code';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text: _companyCodeValidated ? 'Verified' : 'Verify',
                            onPressed: _companyCodeValidated
                                ? null
                                : _validateCompanyCode,
                            isLoading: _isValidatingCode,
                            isEnabled: !_companyCodeValidated &&
                                _companyCodeController.text.trim().isNotEmpty,
                            buttonType: _companyCodeValidated
                                ? ButtonType.success
                                : ButtonType.primary,
                            width: 100,
                          ),
                        ],
                      ),
                      
                      if (_companyCodeValidated && _companyName != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.successColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.successColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Company: $_companyName',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.successColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // First Name
                      CustomTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hintText: 'Enter your first name',
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      CustomTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hintText: 'Enter your last name',
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mobile Number
                      CustomTextField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        hintText: 'Enter your mobile number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mobile number is required';
                          }
                          if (value.length != 10) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Enter your password',
                        obscureText: !_isPasswordVisible,
                        maxLines: 1,
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
                      const SizedBox(height: 16),

                      // Confirm Password
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        obscureText: !_isConfirmPasswordVisible,
                        maxLines: 1,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Signup Button
                      CustomButton(
                        text: 'Sign Up',
                        onPressed: _handleSignup,
                        isLoading: _isLoading,
                        buttonType: ButtonType.primary,
                      ),
                      const SizedBox(height: 16),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacementNamed('/login');
                            },
                            child: Text(
                              'Login',
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
    );
  }
}

