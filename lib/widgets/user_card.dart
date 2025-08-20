import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/user_types.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/site_user_model.dart';
import '../screens/attendance_screen.dart';
import '../core/utils/navigation_utils.dart';
import 'dismiss_keyboard.dart';

class UserCard extends StatelessWidget {
  final SiteUserModel user;
  final VoidCallback? onViewProfile;
  final VoidCallback? onViewAttendance;
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    this.onViewProfile,
    this.onViewAttendance,
    this.onTap,
  });

  Widget _buildProfileImage(BuildContext context) {
    if (user.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 25,
            tablet: 30,
            desktop: 35,
          ),
        ),
        child: Image.network(
          user.imageUrl!,
          width: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 50,
            tablet: 60,
            desktop: 70,
          ),
          height: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 50,
            tablet: 60,
            desktop: 70,
          ),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage(context);
          },
        ),
      );
    } else {
      return _buildPlaceholderImage(context);
    }
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      width: ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 50,
        tablet: 60,
        desktop: 70,
      ),
      height: ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 50,
        tablet: 60,
        desktop: 70,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 25,
            tablet: 30,
            desktop: 35,
          ),
        ),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.textSecondary,
        size: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 24,
          tablet: 28,
          desktop: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap?.call();
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        padding: ResponsiveUtils.responsivePadding(context),
        decoration: BoxDecoration(
          color: AppColors.textWhite,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image
            _buildProfileImage(context),
            
            SizedBox(
              width: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    user.fullName,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 4,
                      tablet: 6,
                      desktop: 8,
                    ),
                  ),
                  
                  // Designation
                  Text(
                    UserTypes.getUserTypeName(user.userType),
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // View Profile Button
                      Expanded(
                        child: GestureDetector(
                          onTap: onViewProfile,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.responsiveSpacing(
                                context,
                                mobile: 6,
                                tablet: 8,
                                desktop: 10,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  desktop: 10,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: AppColors.primaryColor,
                                  size: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                ),
                                SizedBox(
                                  width: ResponsiveUtils.responsiveSpacing(
                                    context,
                                    mobile: 4,
                                    tablet: 6,
                                    desktop: 8,
                                  ),
                                ),
                                Text(
                                  'View Profile',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: ResponsiveUtils.responsiveFontSize(
                                      context,
                                      mobile: 10,
                                      tablet: 12,
                                      desktop: 14,
                                    ),
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(
                        width: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),
                      
                      // View Attendance Button
                      Expanded(
                        child: GestureDetector(
                          onTap: onViewAttendance,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.responsiveSpacing(
                                context,
                                mobile: 6,
                                tablet: 8,
                                desktop: 10,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  desktop: 10,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.successColor,
                                  size: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                ),
                                SizedBox(
                                  width: ResponsiveUtils.responsiveSpacing(
                                    context,
                                    mobile: 4,
                                    tablet: 6,
                                    desktop: 8,
                                  ),
                                ),
                                Text(
                                  'Attendance',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: ResponsiveUtils.responsiveFontSize(
                                      context,
                                      mobile: 10,
                                      tablet: 12,
                                      desktop: 14,
                                    ),
                                    color: AppColors.successColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}
