import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/user_types.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showDrawer;
  final bool showBackButton;
  final VoidCallback? onDrawerPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showDrawer = true,
    this.showBackButton = false,
    this.onDrawerPressed,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final UserModel? user = AuthService.currentUser;
    
    return AppBar(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.textWhite,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () {
                Navigator.of(context).pop();
              },
            )
          : showDrawer
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onDrawerPressed ?? () {
                    Scaffold.of(context).openDrawer();
                  },
                )
              : null,
      title: showDrawer
          ? Row(
        children: [
          // User Profile Icon
          GestureDetector(
            onTap: onProfilePressed,
            child: Container(
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
                color: AppColors.textWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 25,
                  ),
                ),
              ),
              child: user?.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 22,
                          desktop: 25,
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
                              mobile: 20,
                              tablet: 22,
                              desktop: 25,
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
                        mobile: 20,
                        tablet: 22,
                        desktop: 25,
                      ),
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
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User Name
                Text(
                  user?.displayName ?? 'User',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // User Designation
                Text(
                  UserTypes.getUserTypeName(user?.userType),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                    color: AppColors.textWhite.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      )
          : Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: [
        // Notification Icon (only for home screen)
        if (showDrawer)
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationPressed ?? () {
              // Handle notification press
            },
          ),
        // App Version (optional)
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
} 