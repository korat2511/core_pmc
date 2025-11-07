import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/user_assignment_utils.dart';
import '../services/session_manager.dart';
import '../models/site_model.dart';
import '../models/site_user_model.dart';
import '../services/site_user_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import 'attendance_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/user_permissions_screen.dart';
import '../core/utils/navigation_utils.dart';
import '../services/permission_service.dart';

class ManageUserScreen extends StatefulWidget {
  final SiteModel site;

  const ManageUserScreen({
    super.key,
    required this.site,
  });

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  String _searchQuery = '';
  bool _isLoading = false;
  final SiteUserService _siteUserService = SiteUserService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _siteUserService.getUsersBySite(
      siteId: widget.site.id,
    );

    setState(() {
      _isLoading = false;
    });

    if (!success && mounted) {
      // Check for session expiration
      if (_siteUserService.errorMessage.contains('Session expired')) {
        await SessionManager.handleSessionExpired(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: _siteUserService.errorMessage,
        );
      }
    }
  }

  List<SiteUserModel> _getFilteredUsers() {
    List<SiteUserModel> filteredUsers = _siteUserService.users;

    // Filter by search query (local filtering)
    if (_searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.mobile.contains(_searchQuery) ||
               user.designationName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredUsers;
  }


  void _showUserAssignmentModal() {
    UserAssignmentUtils.showUserAssignmentModal(
      context: context,
      site: widget.site,
      onUserAssigned: () {
        // Refresh the user list after assignment
        _loadUsers();
      },
      onUserRemoved: () {
        // Refresh the user list after removal
        _loadUsers();
      },
    );
  }

  void _handleViewProfile(SiteUserModel user) {
    NavigationUtils.push(
      context,
      UserProfileScreen(
        userId: user.id,
      ),
    );
  }

  void _handleViewAttendance(SiteUserModel user) {
    NavigationUtils.push(
      context,
      AttendanceScreen(
        userId: user.id,
        userName: user.fullName,
      ),
    );
  }

  void _handleManagePermissions(SiteUserModel user) {
    // Check if current user can edit users
    if (!PermissionService.canEditUser()) {
      SnackBarUtils.showError(
        context,
        message: "You don't have permission to manage user permissions",
      );
      return;
    }
    
    NavigationUtils.push(
      context,
      UserPermissionsScreen(user: user),
    );
  }


  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Team',
        showDrawer: false,
        showBackButton: true,
      ),
      body: DismissKeyboard(
        child: Column(
        children: [
          // Search Bar and Filter Row
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: CustomSearchBar(
                    hintText: 'Search users...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
              ],
            ),
          ),

          // User Count and Add/Remove Button
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: Row(
              children: [
                Text(
                  '${filteredUsers.length} Users',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // Close keyboard when tapping button
                    FocusScope.of(context).unfocus();
                    _showUserAssignmentModal();
                  },
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
                        mobile: 8,
                        tablet: 10,
                        desktop: 12,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add,
                          color: Colors.white,
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
                            mobile: 4,
                            tablet: 6,
                            desktop: 8,
                          ),
                        ),
                        Text(
                          'Add/Remove User',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
SizedBox(height: 5,),
          // Users List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 60,
                                tablet: 80,
                                desktop: 100,
                              ),
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.responsiveSpacing(
                                context,
                                mobile: 16,
                                tablet: 20,
                                desktop: 24,
                              ),
                            ),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No users found matching your criteria'
                                  : 'No users assigned to this site',
                              style: AppTypography.bodyLarge.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView.builder(
                          padding: ResponsiveUtils.horizontalPadding(context),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return UserCard(
                              user: user,
                              onViewProfile: () => _handleViewProfile(user),
                              onViewAttendance: () => _handleViewAttendance(user),
                              onManagePermissions: () => _handleManagePermissions(user),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    ),
  );
  }
}
