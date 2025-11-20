import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/theme/app_typography.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({super.key});

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // Controllers
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  
  // Logo
  File? _selectedLogoFile;
  String? _currentLogoUrl;
  
  // Company data
  Map<String, dynamic>? _companyData;
  int? _companyId;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _companyDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user?.company == null) {
        if (mounted) {
          SnackBarUtils.showError(context, message: 'No company found');
          NavigationUtils.pop(context);
        }
        return;
      }

      _companyId = user!.company!.id;
      final token = await LocalStorageService.getToken();
      
      if (token == null) {
        if (mounted) {
          SnackBarUtils.showError(context, message: 'Authentication token not found');
          NavigationUtils.pop(context);
        }
        return;
      }

      final response = await ApiService.getCompanyById(
        apiToken: token,
        companyId: _companyId!,
      );

      if (mounted) {
        if (response['status'] == 'success' && response['data'] != null) {
          _companyData = response['data'] as Map<String, dynamic>;
          _populateFields();
        } else {
          SnackBarUtils.showError(
            context,
            message: response['message'] ?? 'Failed to load company details',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Failed to load company details: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _populateFields() {
    if (_companyData == null) return;

    _companyNameController.text = _companyData!['name'] ?? '';
    _companyEmailController.text = _companyData!['email'] ?? '';
    _companyPhoneController.text = _companyData!['phone'] ?? '';
    _companyAddressController.text = _companyData!['address'] ?? '';
    _companyDescriptionController.text = _companyData!['description'] ?? '';
    
    if (_companyData!['logo'] != null) {
      final logoPath = _companyData!['logo'] as String;
      if (logoPath.isNotEmpty) {
        // Construct full URL
        final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
        _currentLogoUrl = logoPath.startsWith('http')
            ? logoPath
            : '$baseUrl/${logoPath.replaceFirst('public/', '')}';
      }
    }
  }

  Future<void> _pickLogo() async {
    final pickedFile = await ImagePickerUtils.showImageSourceDialog(
      context: context,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      // Validate image size (max 2MB)
      final bool isSizeValid = ImagePickerUtils.isImageSizeValid(pickedFile, 2.0);
      if (!isSizeValid) {
        SnackBarUtils.showError(context, message: 'Logo image size cannot exceed 2MB.');
        setState(() {
          _selectedLogoFile = null;
        });
        return;
      }
      
      // Validate aspect ratio (3.8:1)
      final bool isAspectRatioValid = await ImagePickerUtils.isImageAspectRatioValid(
        pickedFile,
        targetRatio: 3.8,
        tolerance: 0.1,
      );
      if (!isAspectRatioValid) {
        final aspectRatio = await ImagePickerUtils.getImageAspectRatio(pickedFile);
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
        _selectedLogoFile = pickedFile;
        _currentLogoUrl = null; // Clear current URL when new file is selected
      });
    }
  }

  Future<void> _handleUpdate() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await LocalStorageService.getToken();
      if (token == null) {
        if (mounted) {
          SnackBarUtils.showError(context, message: 'Authentication token not found');
        }
        return;
      }

      final result = await ApiService.updateCompany(
        apiToken: token,
        companyId: _companyId!,
        name: _companyNameController.text.trim(),
        email: _companyEmailController.text.trim().isEmpty
            ? null
            : _companyEmailController.text.trim(),
        phone: _companyPhoneController.text.trim().isEmpty
            ? null
            : _companyPhoneController.text.trim(),
        address: _companyAddressController.text.trim().isEmpty
            ? null
            : _companyAddressController.text.trim(),
        description: _companyDescriptionController.text.trim().isEmpty
            ? null
            : _companyDescriptionController.text.trim(),
        logoFile: _selectedLogoFile,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['status'] == 'success' || result['status'] == 1) {
          SnackBarUtils.showSuccess(
            context,
            message: result['message'] ?? 'Company updated successfully',
          );
          
          // Refresh company data
          await _loadCompanyData();
          
          // Update user's company info in AuthService
          if (result['data'] != null) {
            final user = AuthService.currentUser;
            if (user != null && user.company != null) {
              final updatedCompany = CompanyInfo.fromJson({
                'id': result['data']['id'],
                'name': result['data']['name'],
                'company_code': result['data']['company_code'],
                'email': result['data']['email'],
              });
              final updatedUser = UserModel.fromJson({
                ...user.toJson(),
                'company': updatedCompany.toJson(),
              });
              await AuthService.updateUser(updatedUser);
            }
          }
        } else {
          SnackBarUtils.showError(
            context,
            message: result['message'] ?? 'Failed to update company',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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
      appBar: CustomAppBar(
        title: 'Company Details',

        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoadingData
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 120,
                                tablet: 140,
                                desktop: 160,
                              ),
                              height: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 120,
                                tablet: 140,
                                desktop: 160,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: _selectedLogoFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _selectedLogoFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _currentLogoUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            _currentLogoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.business,
                                                size: ResponsiveUtils.responsiveFontSize(
                                                  context,
                                                  mobile: 48,
                                                  tablet: 56,
                                                  desktop: 64,
                                                ),
                                                color: AppColors.primaryColor,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.business,
                                          size: ResponsiveUtils.responsiveFontSize(
                                            context,
                                            mobile: 48,
                                            tablet: 56,
                                            desktop: 64,
                                          ),
                                          color: AppColors.primaryColor,
                                        ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickLogo,
                            icon: Icon(Icons.camera_alt_outlined),
                            label: Text(_selectedLogoFile != null || _currentLogoUrl != null
                                ? 'Change Logo'
                                : 'Upload Logo'),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 4,
                              tablet: 6,
                              desktop: 8,
                            ),
                          ),
                          Text(
                            'Logo will be used in PDF reports. Aspect ratio: 3.8:1 (wide format). Max size: 2MB. Recommended: 800x210px or 1600x421px',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 10,
                                tablet: 12,
                                desktop: 14,
                              ),
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 24,
                        tablet: 32,
                        desktop: 40,
                      ),
                    ),

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
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Company Email
                    CustomTextField(
                      controller: _companyEmailController,
                      label: 'Company Email',
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
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Company Phone
                    CustomTextField(
                      controller: _companyPhoneController,
                      label: 'Company Phone',
                      hintText: 'Enter company phone',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(20),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Company Address
                    CustomTextField(
                      controller: _companyAddressController,
                      label: 'Company Address',
                      hintText: 'Enter company address',
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Company Description
                    CustomTextField(
                      controller: _companyDescriptionController,
                      label: 'Description',
                      hintText: 'Enter company description (optional)',
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 24,
                        tablet: 32,
                        desktop: 40,
                      ),
                    ),

                    // Update Button
                    CustomButton(
                      text: 'Update Company',
                      onPressed: _isLoading ? null : _handleUpdate,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

