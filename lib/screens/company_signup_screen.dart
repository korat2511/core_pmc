import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../core/theme/app_typography.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class CompanySignupScreen extends StatefulWidget {
  const CompanySignupScreen({super.key});

  @override
  State<CompanySignupScreen> createState() => _CompanySignupScreenState();
}

class _CompanySignupScreenState extends State<CompanySignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Company Fields
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  
  // Logo file
  File? _selectedLogoFile;
  
  // User Fields (for new account)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Existing user field
  final _existingUserMobileController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _hasAccount = false; // true = existing user, false = new user

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _existingUserMobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await ApiService.companySignup(
          companyName: _companyNameController.text.trim(),
          companyEmail: _companyEmailController.text.trim().isEmpty
              ? null
              : _companyEmailController.text.trim(),
          companyPhone: _companyPhoneController.text.trim().isEmpty
              ? null
              : _companyPhoneController.text.trim(),
          companyAddress: _companyAddressController.text.trim().isEmpty
              ? null
              : _companyAddressController.text.trim(),
          logoFile: _selectedLogoFile,
          hasAccount: _hasAccount,
          userMobile: _hasAccount
              ? _existingUserMobileController.text.trim()
              : null,
          firstName: !_hasAccount ? _firstNameController.text.trim() : null,
          lastName: !_hasAccount ? _lastNameController.text.trim() : null,
          mobile: !_hasAccount ? _mobileController.text.trim() : null,
          email: !_hasAccount ? _emailController.text.trim() : null,
          password: !_hasAccount ? _passwordController.text : null,
          designationId: null, // Will be set by admin later
        );

        setState(() {
          _isLoading = false;
        });

        if (result['status'] == 1) {
          SnackBarUtils.showSuccess(
            context,
            message:
                'Company created successfully! ${_hasAccount ? '' : 'Please login with your credentials.'}',
          );
          
          // Show company code dialog
          if (result['company_code'] != null) {
            _showCompanyCodeDialog(result['company_code']);
          } else {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else {
          SnackBarUtils.showError(
            context,
            message: result['message'] ?? 'Company signup failed',
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

  void _showCompanyCodeDialog(String companyCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Company Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your company code is:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
              child: Text(
                companyCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share this code with your team members to join your company.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Continue to Login'),
          ),
        ],
      ),
    );
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
                      'assets/images/pmc.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Register Company',
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
                    'Create a new company account and get a unique company code to share with your team',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Company Details
                      Text(
                        'Company Details',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Company Name
                      CustomTextField(
                        controller: _companyNameController,
                        label: 'Company Name *',
                        hintText: 'Enter company name',
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Company name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Company Email
                      CustomTextField(
                        controller: _companyEmailController,
                        label: 'Company Email (Optional)',
                        hintText: 'Enter company email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Company Phone
                      CustomTextField(
                        controller: _companyPhoneController,
                        label: 'Company Phone (Optional)',
                        hintText: 'Enter company phone',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Company Address
                      CustomTextField(
                        controller: _companyAddressController,
                        label: 'Company Address (Optional)',
                        hintText: 'Enter company address',
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Company Logo Section
                      Text(
                        'Company Logo (Optional)',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Logo Upload Button and Preview
                      Row(
                        children: [
                          // Logo Preview/Upload Button
                          GestureDetector(
                            onTap: () async {
                              final file = await ImagePickerUtils.showImageSourceDialog(
                                context: context,
                                chooseMultiple: false,
                                imageQuality: 85,
                              );
                              if (file != null && mounted) {
                                // Validate image size (max 2MB)
                                if (!ImagePickerUtils.isImageSizeValid(file, 2.0)) {
                                  SnackBarUtils.showError(
                                    context,
                                    message: 'Image size must be less than 2MB',
                                  );
                                  return;
                                }
                                
                                // Validate image dimensions (max 512x512)
                                // Validate image size (max 2MB)
                                final isValidSize = ImagePickerUtils.isImageSizeValid(file, 2.0);
                                if (!isValidSize) {
                                  SnackBarUtils.showError(
                                    context,
                                    message: 'Logo image size cannot exceed 2MB.',
                                  );
                                  setState(() {
                                    _selectedLogoFile = null;
                                  });
                                  return;
                                }
                                
                                // Validate aspect ratio (3.8:1)
                                final isValidAspectRatio = await ImagePickerUtils.isImageAspectRatioValid(
                                  file,
                                  targetRatio: 3.8,
                                  tolerance: 0.1,
                                );
                                if (!isValidAspectRatio) {
                                  final aspectRatio = await ImagePickerUtils.getImageAspectRatio(file);
                                  SnackBarUtils.showError(
                                    context,
                                    message: 'Logo aspect ratio must be approximately 3.8:1 (wide format). Current ratio: ${aspectRatio?.toStringAsFixed(2) ?? 'N/A'}:1. Recommended dimensions: 800x210px or 1600x421px.',
                                  );
                                  setState(() {
                                    _selectedLogoFile = null;
                                  });
                                  return;
                                }
                                
                                setState(() {
                                  _selectedLogoFile = file;
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: _selectedLogoFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedLogoFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: AppColors.primaryColor,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add Logo',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Remove Logo Button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_selectedLogoFile != null)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedLogoFile = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: const Text('Remove Logo'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Logo will be used in PDF reports. Aspect ratio: 3.8:1 (wide format). Max size: 2MB. Recommended: 800x210px or 1600x421px',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section: Owner/Admin Details
                      Text(
                        'Owner/Admin Details',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle: Has Account or New Account
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _hasAccount = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_hasAccount
                                        ? AppColors.primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'New Account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_hasAccount
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: !_hasAccount
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _hasAccount = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _hasAccount
                                        ? AppColors.primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'I have account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _hasAccount
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: _hasAccount
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Conditional Fields based on _hasAccount
                      if (_hasAccount) ...[
                        // Existing User: Mobile Number
                        CustomTextField(
                          controller: _existingUserMobileController,
                          label: 'Your Mobile Number *',
                          hintText: 'Enter your registered mobile number',
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
                      ] else ...[
                        // New User: Full Registration Form
                        CustomTextField(
                          controller: _firstNameController,
                          label: 'First Name *',
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

                        CustomTextField(
                          controller: _lastNameController,
                          label: 'Last Name *',
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

                        CustomTextField(
                          controller: _mobileController,
                          label: 'Mobile Number *',
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

                        CustomTextField(
                          controller: _emailController,
                          label: 'Email *',
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

                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password *',
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

                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password *',
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
                      ],
                      const SizedBox(height: 32),

                      // Create Company Button
                      CustomButton(
                        text: 'Create Company',
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
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
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
                      
                      // Regular Signup Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Want to join existing company? ',
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

