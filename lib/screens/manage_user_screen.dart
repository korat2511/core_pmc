import 'package:core_pmc/widgets/dismiss_keyboard.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/session_manager.dart';
import '../models/site_model.dart';
import '../models/site_user_model.dart';
import '../services/site_user_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_bar.dart';

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
      search: _searchQuery,
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

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.mobile.contains(_searchQuery);
      }).toList();
    }

    return filteredUsers;
  }

  void _handleViewProfile(SiteUserModel user) {
    closeKeyboard(context);
    print('View profile for: ${user.fullName}');
  }

  void _handleViewAttendance(SiteUserModel user) {
    closeKeyboard(context);
    print('View attendance for: ${user.fullName}');
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return DismissKeyboard(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Manage Team',
          showDrawer: false,
          showBackButton: true,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: ResponsiveUtils.responsivePadding(context),
              child: CustomSearchBar(
                hintText: 'Search users...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _loadUsers();
                },
              ),
            ),

            // User Count
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
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
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Users List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
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
                                color: AppColors.textSecondary,
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
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          color: AppColors.primaryColor,
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
