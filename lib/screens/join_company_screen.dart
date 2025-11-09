import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';

class JoinCompanyScreen extends StatefulWidget {
  final int userId;

  const JoinCompanyScreen({
    super.key,
    required this.userId,
  });

  @override
  State<JoinCompanyScreen> createState() => _JoinCompanyScreenState();
}

class _JoinCompanyScreenState extends State<JoinCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCodeController = TextEditingController();

  bool _isValidating = false;
  bool _isJoining = false;
  Map<String, dynamic>? _company;

  @override
  void dispose() {
    _companyCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateCompanyCode() async {
    final code = _companyCodeController.text.trim();
    if (code.isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter company code');
      return;
    }

    setState(() {
      _isValidating = true;
      _company = null;
    });

    try {
      final result = await ApiService.validateCompanyCode(companyCode: code);
      setState(() {
        _isValidating = false;
      });

      if (result['status'] == 1) {
        setState(() {
          _company = Map<String, dynamic>.from(result['company'] ?? {});
        });
        SnackBarUtils.showSuccess(context, message: 'Company code verified');
      } else {
        SnackBarUtils.showError(
          context,
          message: result['message'] ?? 'Invalid company code',
        );
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to validate company code',
      );
    }
  }

  Future<void> _joinCompany() async {
    if (_company == null) {
      SnackBarUtils.showError(
        context,
        message: 'Please validate the company code first',
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final parsedCompanyId = _company!['id'] is int
          ? _company!['id'] as int
          : int.tryParse('${_company!['id']}');
      if (parsedCompanyId == null) {
        setState(() {
          _isJoining = false;
        });
        SnackBarUtils.showError(
          context,
          message: 'Unable to read company information. Please validate again.',
        );
        return;
      }

      final result = await ApiService.addUserToCompany(
        userId: widget.userId,
        companyId: parsedCompanyId,
        isPrimary: true,
      );

      setState(() {
        _isJoining = false;
      });

      if (result['status'] == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Joined company successfully! Please login.',
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        SnackBarUtils.showError(
          context,
          message: result['message'] ?? 'Failed to join company',
        );
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Join Company'),
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
                Text(
                  'Join your team',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the company code shared by your administrator to join your company workspace.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _companyCodeController,
                        label: 'Company Code',
                        hintText: 'Enter company code',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company code is required';
                          }
                          if (_company == null) {
                            return 'Please validate company code';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          setState(() {
                            _company = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: _company != null ? 'Verified' : 'Validate',
                              onPressed:
                                  _company != null ? null : _validateCompanyCode,
                              isLoading: _isValidating,
                              isEnabled: _companyCodeController.text
                                  .trim()
                                  .isNotEmpty,
                              buttonType: _company != null
                                  ? ButtonType.success
                                  : ButtonType.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: 'Join Company',
                              onPressed: _joinCompany,
                              isEnabled: _company != null && !_isJoining,
                              isLoading: _isJoining,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_company != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: ResponsiveUtils.responsivePadding(context),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Details',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Name: ${_company?['name'] ?? '-'}',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${_company?['company_code'] ?? '-'}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

