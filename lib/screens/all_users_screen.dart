import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/user_types.dart';
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
import '../core/utils/navigation_utils.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  String _searchQuery = '';
  int _selectedUserType = 0; // 0 means all user types
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
            user.mobile.contains(_searchQuery);
      }).toList();
    }

    // Filter by user type (client-side filtering)
    if (_selectedUserType > 0) {
      filteredUsers = filteredUsers.where((user) {
        return user.userType == _selectedUserType;
      }).toList();
    }

    return filteredUsers;
  }

  void _onUserTypeChanged(int userType) {
    setState(() {
      _selectedUserType = userType;
    });
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

  String _getFilterText() {
    if (_selectedUserType == 0) {
      return 'All Users';
    }
    return UserTypes.getUserTypeName(_selectedUserType);
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Filter by Designation',
              style: AppTypography.titleMedium.copyWith(
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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFilterOption('All Users', 0),
                    _buildFilterOption('Project Coordinator', 1),
                    _buildFilterOption('Senior Executive', 2),
                    _buildFilterOption('Supervisor', 3),
                    _buildFilterOption('Site Executive', 4),
                    _buildFilterOption('Owner', 5),
                    _buildFilterOption('Agency', 6),
                    _buildFilterOption('Design Team', 7),
                    _buildFilterOption('Vendor', 8),
                  ],
                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, int userType) {
    final isSelected = _selectedUserType == userType;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          fontSize: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 16,
            tablet: 18,
            desktop: 20,
          ),
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedUserType = userType;
        });
        Navigator.pop(context);
      },
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

                  SizedBox(
                    width: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                  ),

                  // Filter Button
                  GestureDetector(
                    onTap: () {
                      _showFilterOptions();
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
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                        border: Border.all(
                          color: AppColors.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
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
                              mobile: 4,
                              tablet: 6,
                              desktop: 8,
                            ),
                          ),
                          Text(
                            _getFilterText(),
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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
