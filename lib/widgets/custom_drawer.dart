import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/all_users_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/to_do_list.dart';
import '../providers/theme_provider.dart';
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

  void _showCompanySelector(BuildContext context) {
    final UserModel? user = AuthService.currentUser;
    if (user?.allowedCompanies == null || user!.allowedCompanies!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Company',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which company to work with',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                ...user.allowedCompanies!.map((company) {
                  final isCurrentCompany = company.id == user.companyId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrentCompany
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: isCurrentCompany
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      company.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: isCurrentCompany ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentCompany
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: company.companyCode != null
                        ? Text(
                            company.companyCode!,
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          )
                        : null,
                    trailing: isCurrentCompany
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: isCurrentCompany
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                            _switchCompany(context, company.id);
                          },
                  );
                }).toList(),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _switchCompany(BuildContext context, int companyId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Switching company...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await AuthService.switchCompany(companyId);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (result['success']) {
        // Close drawer
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${result['companyName'] ?? 'new company'}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Data refresh is handled by CompanyNotifier stream in individual screens
        // Home screen and other screens listening to the stream will auto-refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to switch company'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final UserModel? user = AuthService.currentUser;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
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
                                color: Theme.of(context).colorScheme.onPrimary,
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
                          color: Theme.of(context).colorScheme.onPrimary,
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
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 2,
                          tablet: 3,
                          desktop: 4,
                        ),
                      ),
                      // User Designation
                      Text(
                        user?.designationDisplay ?? 'Employee',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 2,
                          tablet: 3,
                          desktop: 4,
                        ),
                      ),
                      // Company Name - Tappable to switch companies
                      InkWell(
                        onTap: user?.hasMultipleCompanies == true
                            ? () {
                                print('DEBUG: Tapped company switcher');
                                print('DEBUG: allowedCompanies count: ${user?.allowedCompanies?.length ?? 0}');
                                _showCompanySelector(context);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: user?.hasMultipleCompanies == true
                              ? BoxDecoration(
                                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                )
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  user?.companyName ?? 'PMC',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: ResponsiveUtils.responsiveFontSize(
                                      context,
                                      mobile: 12,
                                      tablet: 14,
                                      desktop: 16,
                                    ),
                                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                                    fontWeight: user?.hasMultipleCompanies == true 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user?.hasMultipleCompanies == true) ...[
                                SizedBox(width: 4),
                                Icon(
                                  Icons.expand_more,
                                  size: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 16,
                                    tablet: 18,
                                    desktop: 20,
                                  ),
                                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                    if (user != null) {
                      NavigationUtils.push(
                        context,
                        AttendanceScreen(
                          userId: user.id,
                          userName: user.displayName,
                        ),
                      );
                    }
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
                // To-Do List
                _buildDrawerItem(
                  context,
                  icon: Icons.task_outlined,
                  title: 'To-Do List',
                  onTap: () {
                    NavigationUtils.push(context, const ToDoList());
                  },
                ),
                // Theme Toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildDrawerItem(
                      context,
                      icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      title: themeProvider.isDarkMode ? 'Light Theme' : 'Dark Theme',
                      onTap: () {
                        themeProvider.toggleTheme();
                      },
                    );
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
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ),
          // App Version at Bottom
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Loading package info...');
              } else if (snapshot.hasData && snapshot.data != null) {
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
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: iconColor ?? Theme.of(context).colorScheme.onSurface,
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
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}