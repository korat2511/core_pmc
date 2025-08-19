import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/user_types.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/all_users_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CustomDrawer extends StatefulWidget {
  final VoidCallback? onViewProfile;
  final VoidCallback? onViewAttendance;
  final VoidCallback? onLogout;

  const CustomDrawer({
    super.key,
    this.onViewProfile,
    this.onViewAttendance,
    this.onLogout,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String appVersion = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    getAppVersion();
  }

  Future<void> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }


  @override
  Widget build(BuildContext context) {
    final UserModel? user = AuthService.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: ResponsiveUtils.responsiveSpacing(context),
              right: ResponsiveUtils.responsiveSpacing(context),
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: Row(
              children: [
                // User Profile Image
                Container(
                  width: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 60,
                    tablet: 70,
                    desktop: 80,
                  ),
                  height: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 60,
                    tablet: 70,
                    desktop: 80,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 30,
                        tablet: 35,
                        desktop: 40,
                      ),
                    ),
                  ),
                  child: user?.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 30,
                              tablet: 35,
                              desktop: 40,
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
                                  mobile: 30,
                                  tablet: 35,
                                  desktop: 40,
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
                            mobile: 30,
                            tablet: 35,
                            desktop: 40,
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
                // User Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // User Name
                      Text(
                        user?.displayName ?? 'User',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: AppColors.textWhite,
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
                      // User Designation
                      Text(
                        UserTypes.getUserTypeName(user?.userType),
                        style: AppTypography.bodyMedium.copyWith(
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
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // View Profile
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'View Profile',
                  onTap: widget.onViewProfile ?? () {
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                // View Attendance
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'View Attendance',
                  onTap: widget.onViewAttendance ?? () {
                    // Handle view attendance
                  },
                ),
                // View All Users
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'View All Users',
                  onTap: () {
                    NavigationUtils.push(context, const AllUsersScreen());
                  },
                ),
                const Divider(),
                // Logout
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: widget.onLogout ?? () {
                    AuthService.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  textColor: AppColors.errorColor,
                  iconColor: AppColors.errorColor,
                ),
              ],
            ),
          ),
          // App Version at Bottom
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              String version = 'v1.25.0(1)';

              if (snapshot.connectionState == ConnectionState.waiting) {
                version = 'Loading...';
              } else if (snapshot.hasData && snapshot.data != null) {
                version = 'v${snapshot.data!.version}(${snapshot.data!.buildNumber})';
                print('Package info loaded: ${snapshot.data!.version} - ${snapshot.data!.buildNumber}');
              } else if (snapshot.hasError) {
                print('Error getting package info: ${snapshot.error}');
              } else {
                print('Package info is null or loading...');
              }

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 16,
                    tablet: 20,
                    desktop: 24,
                  ),
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
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
                    Text(
                      'App version: $appVersion ($buildNumber)',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textPrimary,
        size: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 20,
          tablet: 22,
          desktop: 24,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          fontSize: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 16,
            tablet: 18,
            desktop: 20,
          ),
          color: textColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}