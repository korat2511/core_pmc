import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/session_manager.dart';
import '../models/site_user_model.dart';
import '../services/all_user_service.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import 'attendance_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/user_permissions_screen.dart';
import '../core/utils/navigation_utils.dart';
import '../services/permission_service.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  String _searchQuery = '';
  bool _isLoading = false;
  final AllUserService _allUserService = AllUserService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _allUserService.getAllUsers();

    setState(() {
      _isLoading = false;
    });

    if (!success && mounted) {
      // Check for session expiration
      if (_allUserService.errorMessage.contains('Session expired')) {
        await SessionManager.handleSessionExpired(context);
      } else {
        SnackBarUtils.showError(context, message: _allUserService.errorMessage);
      }
    }
  }

  List<SiteUserModel> _getFilteredUsers() {
    List<SiteUserModel> filteredUsers = _allUserService.users;

    // Filter by search query (local filtering)
    if (_searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        return user.fullName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.mobile.contains(_searchQuery) ||
            user.designationName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredUsers;
  }

  void _handleViewProfile(SiteUserModel user) {
    NavigationUtils.push(context, UserProfileScreen(userId: user.id));
  }

  void _handleViewAttendance(SiteUserModel user) {
    NavigationUtils.push(
      context,
      AttendanceScreen(userId: user.id, userName: user.fullName),
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
        title: 'All Users',
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

            // User Count
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
                ],
              ),
            ),
            SizedBox(height: 5),
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
                            'No users found',
                            style: AppTypography.bodyLarge.copyWith(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView.builder(
                        padding: ResponsiveUtils.responsivePadding(context),
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
