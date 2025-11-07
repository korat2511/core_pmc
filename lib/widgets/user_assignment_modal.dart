import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/site_user_model.dart';
import '../models/site_user_response.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/user_assignment_button.dart';

class UserAssignmentModal extends StatefulWidget {
  final SiteModel site;
  final List<SiteUserModel> allUsers;
  final List<SiteUserModel> siteUsers;
  final VoidCallback? onUserAssigned;
  final VoidCallback? onUserRemoved;

  const UserAssignmentModal({
    super.key,
    required this.site,
    required this.allUsers,
    required this.siteUsers,
    this.onUserAssigned,
    this.onUserRemoved,
  });

  @override
  State<UserAssignmentModal> createState() => _UserAssignmentModalState();
}

class _UserAssignmentModalState extends State<UserAssignmentModal> {
  bool _isLoading = false;
  String _searchQuery = '';


  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
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
                          'Manage Site Users',
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
                        Text(
                          widget.site.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: ResponsiveUtils.responsivePadding(context),
              child: CustomSearchBar(
                hintText: 'Search users...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // User Count
            Padding(
              padding: ResponsiveUtils.horizontalPadding(context),
              child: Row(
                children: [
                  Text(
                    '${filteredUsers.length} Users',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
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
                                  mobile: 48,
                                  tablet: 56,
                                  desktop: 64,
                                ),
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(
                                height: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  desktop: 20,
                                ),
                              ),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No users found matching your search'
                                    : 'No users available',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: ResponsiveUtils.horizontalPadding(context),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final isAssigned = _isUserAssignedToSite(user);
                            
                            return _buildUserCard(user, isAssigned);
                          },
                        ),
            ),
            
            // Bottom padding
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

  List<SiteUserModel> _getFilteredUsers() {
    List<SiteUserModel> filteredUsers = widget.allUsers;

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

  bool _isUserAssignedToSite(SiteUserModel user) {
    if (user.siteId == null || user.siteId!.isEmpty) return false;
    
    final siteIds = user.siteIds;
    return siteIds.contains(widget.site.id);
  }

  Widget _buildUserCard(SiteUserModel user, bool isAssigned) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
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
      child: ListTile(
        contentPadding: ResponsiveUtils.responsivePadding(context),
        leading: _buildUserAvatar(user),
        title: Text(
          user.fullName,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              user.designationName,
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
            SizedBox(height: 2),
            Text(
              user.email,
              style: AppTypography.bodySmall.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: UserAssignmentButton(
          user: user,
          siteId: widget.site.id,
          initialIsAssigned: isAssigned,
          onUserAssigned: widget.onUserAssigned,
          onUserRemoved: widget.onUserRemoved,
        ),
      ),
    );
  }

  Widget _buildUserAvatar(SiteUserModel user) {
    if (user.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 20,
            tablet: 24,
            desktop: 28,
          ),
        ),
        child: Image.network(
          user.imageUrl!,
          width: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 40,
            tablet: 48,
            desktop: 56,
          ),
          height: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 40,
            tablet: 48,
            desktop: 56,
          ),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderAvatar();
          },
        ),
      );
    } else {
      return _buildPlaceholderAvatar();
    }
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 40,
        tablet: 48,
        desktop: 56,
      ),
      height: ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 40,
        tablet: 48,
        desktop: 56,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 20,
            tablet: 24,
            desktop: 28,
          ),
        ),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 20,
          tablet: 24,
          desktop: 28,
        ),
      ),
    );
  }

}
