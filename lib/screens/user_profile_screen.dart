import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/user_types.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = AuthService.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        showDrawer: false,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          children: [
            // Profile Header
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
                color: AppColors.errorColor,
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
                      color: AppColors.textWhite,
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
                color: AppColors.textWhite,
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
            // Profile Details
            Container(
              width: double.infinity,
              padding: ResponsiveUtils.responsivePadding(context),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
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
                      color: AppColors.textPrimary,
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
                  // Personal Information
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
                    icon: Icons.work_outline,
                    title: 'Designation',
                    value: UserTypes.getUserTypeName(user?.userType),
                  ),

                  _buildProfileItem(
                    context,
                    icon: Icons.circle_outlined,
                    title: 'Status',
                    value: user?.status ?? 'N/A',
                    valueColor: user?.isActive == true 
                        ? AppColors.successColor 
                        : AppColors.errorColor,
                  ),
                  if (user?.siteId != null) ...[
                    _buildProfileItem(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'Site ID',
                      value: user!.siteId.toString(),
                    ),
                  ],


                  _buildProfileItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Joined On',
                    value: _formatDate(user?.createdAt) ?? 'N/A',
                  ),
                ],
              ),
            ),
          ],
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
              color: AppColors.primaryColor.withOpacity(0.1),
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
              color: AppColors.primaryColor,
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
                    color: AppColors.textSecondary,
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
                    color: valueColor ?? AppColors.textPrimary,
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