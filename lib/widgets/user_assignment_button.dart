import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/site_user_model.dart';
import '../models/site_user_response.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../core/utils/snackbar_utils.dart';

class UserAssignmentButton extends StatefulWidget {
  final SiteUserModel user;
  final int siteId;
  final bool initialIsAssigned;
  final VoidCallback? onUserAssigned;
  final VoidCallback? onUserRemoved;

  const UserAssignmentButton({
    super.key,
    required this.user,
    required this.siteId,
    required this.initialIsAssigned,
    this.onUserAssigned,
    this.onUserRemoved,
  });

  @override
  State<UserAssignmentButton> createState() => _UserAssignmentButtonState();
}

class _UserAssignmentButtonState extends State<UserAssignmentButton> {
  bool _isAssigned = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isAssigned = widget.initialIsAssigned;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleUserAction,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
          vertical: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 6,
            tablet: 8,
            desktop: 10,
          ),
        ),
        decoration: BoxDecoration(
          color: _isAssigned ? AppColors.errorColor : AppColors.primaryColor,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                height: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                ),
              )
            : Text(
                _isAssigned ? 'Remove' : 'Assign',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Future<void> _handleUserAction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      SiteUserResponse response;
      
      if (_isAssigned) {
        // Remove user from site
        response = await ApiService.removeUserFromSite(
          apiToken: apiToken,
          userId: widget.user.id,
          siteId: widget.siteId,
        );
      } else {
        // Assign user to site
        response = await ApiService.assignSite(
          apiToken: apiToken,
          userId: widget.user.id,
          siteId: widget.siteId,
        );
      }

      if (response.isSuccess) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message,
        );
        
        // Update button state
        setState(() {
          _isAssigned = !_isAssigned;
        });
        
        // Call callbacks to refresh parent screens
        if (_isAssigned) {
          widget.onUserAssigned?.call();
        } else {
          widget.onUserRemoved?.call();
        }
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message,
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to ${_isAssigned ? 'remove' : 'assign'} user: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
