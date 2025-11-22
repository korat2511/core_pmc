import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_detail_service.dart';
import '../services/session_manager.dart';
import '../services/permission_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import 'edit_user_screen.dart';
import 'change_password_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int? userId; // If null, shows current user's profile

  const UserProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserDetailService _userDetailService = UserDetailService();
  int? _profileUserId;

  @override
  void initState() {
    super.initState();
    final currentUser = AuthService.currentUser;
    _profileUserId = widget.userId ?? currentUser?.id;
    if (_profileUserId != null) {
      _loadUserDetails();
    }
  }

  bool get _isSelf {
    final currentUser = AuthService.currentUser;
    if (_profileUserId == null || currentUser == null) return false;
    return currentUser.id == _profileUserId;
  }

  Future<void> _loadUserDetails() async {
    if (_profileUserId == null) return;

    final success = await _userDetailService.getUserDetails(_profileUserId!);

    if (!mounted) return;

    if (success) {
      if (_isSelf && _userDetailService.user != null) {
        await AuthService.updateUser(_userDetailService.user!);
      }
      setState(() {});
    } else {
      final error = _userDetailService.errorMessage;
      if (error.contains('Session expired')) {
        await SessionManager.handleSessionExpired(context);
      } else if (error.isNotEmpty) {
        SnackBarUtils.showError(context, message: error);
      }
    }
  }

  bool _canEdit(UserModel? user) {
    if (user == null) return false;
    if (_isSelf) return true;
    return PermissionService.canEditUser() || PermissionService.canManageDesignations();
  }

  Future<void> _handleEdit(UserModel user) async {
    final result = await NavigationUtils.push(
      context,
      EditUserScreen(
        user: user,
        canEditImage: _isSelf,
        canEditStatus: PermissionService.canManageDesignations(),
      ),
    );

    if (result == true) {
      await _loadUserDetails();
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = _userDetailService.user ?? (_isSelf ? AuthService.currentUser : null);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.userId != null ? 'User Profile' : 'My Profile',
        showDrawer: false,
        showBackButton: true,
        actions: _canEdit(user)
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _handleEdit(user!),
                  tooltip: 'Edit User',
                )
              ]
            : null,
      ),
      body: _userDetailService.isLoading && user == null
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
                    : RefreshIndicator(
              onRefresh: _loadUserDetails,
              color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
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
              child: user?.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 60,
                    tablet: 70,
                    desktop: 80,
                  ),
                ),
                child: Image.network(
                  user!.imageUrl!,
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
                ),
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
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 24,
                tablet: 32,
                desktop: 40,
              ),
            ),
                Container(
                  width: double.infinity,
                  padding: ResponsiveUtils.responsivePadding(context),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),
                    border: Border.all(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Details',
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
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
                      _buildProfileItem(
                        context,
                        icon: Icons.badge_outlined,
                        title: 'User ID',
                        value: user?.id.toString() ?? 'N/A',
                      ),
                      _buildProfileItem(
                        context,
                        icon: Icons.person_outline,
                        title: 'Full Name',
                        value: user?.fullName ?? 'N/A',
                      ),
                      _buildProfileItem(
                        context,
                        icon: Icons.phone_outlined,
                        title: 'Mobile Number',
                        value: user?.mobile ?? 'N/A',
                      ),
                      _buildProfileItem(
                        context,
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: user?.email ?? 'N/A',
                      ),
                      _buildProfileItem(
                        context,
                            icon: Icons.business_center_outlined,
                        title: 'Designation',
                        value: user?.designationDisplay ?? 'Employee',
                      ),
                          _buildProfileItem(
                            context,
                            icon: Icons.apartment_outlined,
                            title: 'Company',
                            value: user?.companyName ?? 'N/A',
                          ),
                      _buildProfileItem(
                        context,
                        icon: Icons.circle_outlined,
                        title: 'Status',
                        value: user?.status ?? 'N/A',
                        valueColor: user?.isActive == true
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                      _buildProfileItem(
                        context,
                        icon: Icons.calendar_today_outlined,
                        title: 'Joined On',
                        value: _formatDate(user?.createdAt) ?? 'N/A',
                      ),
                      
                      // Change Password Button (only for self)
                      if (_isSelf) ...[
                        SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                        Divider(),
                        SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                        CustomButton(
                          text: 'Change Password',
                          onPressed: () async {
                            final result = await NavigationUtils.push(
                              context,
                              ChangePasswordScreen(),
                            );
                            if (result == true) {
                              // Password changed successfully
                              SnackBarUtils.showSuccess(
                                context,
                                message: 'Password changed successfully',
                              );
                            }
                          },
                          buttonType: ButtonType.secondary,
                        ),
                      ],
                    ],
                  ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 16,
          tablet: 16,
          desktop: 20,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 45,
              desktop: 50,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 45,
              desktop: 50,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 25,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
          ),
          SizedBox(
            width: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 2,
                    tablet: 4,
                    desktop: 6,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 