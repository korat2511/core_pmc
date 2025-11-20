import 'package:flutter/material.dart';
import 'dart:io';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/user_model.dart';
import '../models/designation_model.dart';
import '../services/user_detail_service.dart';
import '../services/designation_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../core/utils/image_picker_utils.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  final bool canEditImage;
  final bool canEditStatus;

  const EditUserScreen({
    super.key,
    required this.user,
    required this.canEditImage,
    required this.canEditStatus,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserDetailService _userDetailService = UserDetailService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;

  bool _isSaving = false;
  File? _selectedImage;
  int? _selectedDesignationId;
  String? _statusValue;
  bool _isLoadingDesignations = false;
  List<DesignationModel> _designations = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _mobileController = TextEditingController(text: widget.user.mobile);
    _selectedDesignationId = widget.user.designationId;
    final status = widget.user.status;
    if (status.isNotEmpty) {
      _statusValue = '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
    } else {
      _statusValue = 'Active';
    }

    if (widget.canEditStatus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDesignations();
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadDesignations() async {
    final companyId = widget.user.companyId ?? AuthService.currentUser?.companyId;
    if (companyId == null) {
      return;
    }

    setState(() {
      _isLoadingDesignations = true;
    });

    final success = await DesignationService.loadDesignations(companyId: companyId);

    if (!mounted) return;

    setState(() {
      _isLoadingDesignations = false;
      if (success) {
        final loaded = List<DesignationModel>.from(DesignationService.designations);
        final Map<int, DesignationModel> uniqueById = {};
        for (final designation in loaded) {
          uniqueById[designation.id] = designation;
        }
        _designations = uniqueById.values.toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (_selectedDesignationId == null ||
            !_designations.any((designation) => designation.id == _selectedDesignationId)) {
          _selectedDesignationId = _designations.isNotEmpty ? _designations.first.id : null;
        }
      } else {
        SnackBarUtils.showError(
          context,
          message: DesignationService.errorMessage.isNotEmpty
              ? DesignationService.errorMessage
              : 'Failed to load designations',
        );
      }
    });
  }

  Future<void> _pickProfileImage() async {
    if (!widget.canEditImage) return;
    final image = await ImagePickerUtils.showImageSourceDialog(context: context);
    if (image != null && mounted) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final success = await _userDetailService.updateUser(
      userId: widget.user.id,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      status: widget.canEditStatus ? _statusValue : null,
      designationId: widget.canEditStatus ? _selectedDesignationId : null,
      image: _selectedImage,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final error = _userDetailService.errorMessage;
      if (error.isNotEmpty) {
        SnackBarUtils.showError(context, message: error);
      } else {
        SnackBarUtils.showError(context, message: 'Failed to update user. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(
          'Edit User',
          style: AppTypography.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: widget.canEditImage ? _pickProfileImage : null,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
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
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 60,
                              tablet: 70,
                              desktop: 80,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 60,
                              tablet: 70,
                              desktop: 80,
                            ),
                          ),
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : widget.user.imageUrl != null
                                  ? Image.network(
                                      widget.user.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          size: ResponsiveUtils.responsiveFontSize(
                                            context,
                                            mobile: 60,
                                            tablet: 70,
                                            desktop: 80,
                                          ),
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.person,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      size: ResponsiveUtils.responsiveFontSize(
                                        context,
                                        mobile: 60,
                                        tablet: 70,
                                        desktop: 80,
                                      ),
                                    ),
                        ),
                      ),
                      if (widget.canEditImage)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!widget.canEditImage)
                Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
                  child: Text(
                    'Only the account owner can change the profile picture.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 24,
                  tablet: 28,
                  desktop: 32,
                ),
              ),
              CustomTextField(
                controller: _firstNameController,
                label: 'First Name',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
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
              CustomTextField(
                controller: _lastNameController,
                label: 'Last Name',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
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
              CustomTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (value.trim().length != 10) {
                    return 'Enter a valid 10-digit mobile number';
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
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email address';
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
              widget.canEditStatus
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: ResponsiveUtils.responsivePadding(context),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Designation',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  desktop: 10,
                                ),
                              ),
                              if (_isLoadingDesignations)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              else if (_designations.isEmpty)
                                Text(
                                  'No designations found for this company.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              else
                                DropdownButtonFormField<int>(
                                  value: _selectedDesignationId != null &&
                                          _designations.any(
                                            (designation) => designation.id == _selectedDesignationId,
                                          )
                                      ? _selectedDesignationId
                                      : _designations.first.id,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _designations
                                      .map(
                                        (designation) => DropdownMenuItem<int>(
                                          value: designation.id,
                                          child: Text(designation.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDesignationId = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a designation';
                                    }
                                    return null;
                                  },
                                ),
                              SizedBox(
                                height: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                              ),
                              Text(
                                'Status',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  desktop: 10,
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: _statusValue,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Inactive',
                                    child: Text('Inactive'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _statusValue = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      padding: ResponsiveUtils.responsivePadding(context),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Designation',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 6,
                              tablet: 8,
                              desktop: 10,
                            ),
                          ),
                          Text(
                            widget.user.designationDisplay,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                          ),
                          Text(
                            'Status',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 6,
                              tablet: 8,
                              desktop: 10,
                            ),
                          ),
                          Text(
                            widget.user.status,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.user.isActive
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 32,
                  tablet: 36,
                  desktop: 40,
                ),
              ),
              Center(
                child: CustomButton(
                  text: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
