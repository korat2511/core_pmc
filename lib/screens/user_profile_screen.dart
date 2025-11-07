import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/user_model.dart';
import '../models/site_model.dart';
import '../services/auth_service.dart';
import '../services/user_detail_service.dart';
import '../services/user_sites_service.dart';
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';

class UserProfileScreen extends StatefulWidget {
  final int? userId; // If null, shows current user's profile

  const UserProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserDetailService _userDetailService = UserDetailService();
  final UserSitesService _userSitesService = UserSitesService();

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _loadUserDetails();
      _loadUserSites();
    } else {
      // For current user's profile, load their sites
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        _loadUserSites();
      }
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  Future<void> _loadUserDetails() async {
    if (widget.userId == null) return;

    final success = await _userDetailService.getUserDetails(widget.userId!);
    
    if (success) {
      setState(() {});
    } else {
      if (mounted) {
        // Check for session expiration
        if (_userDetailService.errorMessage.contains('Session expired')) {
          await SessionManager.handleSessionExpired(context);
        } else {
          SnackBarUtils.showError(
            context, 
            message: _userDetailService.errorMessage
          );
        }
      }
    }
  }

  Future<void> _loadUserSites() async {
    int? userId = widget.userId;
    if (userId == null) {
      // For current user's profile
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return;
      userId = currentUser.id;
    }

    final success = await _userSitesService.getSitesByUser(userId: userId);
    
    if (success) {
      setState(() {});
    } else {
      if (mounted) {
        // Check for session expiration
        if (_userSitesService.errorMessage.contains('Session expired')) {
          await SessionManager.handleSessionExpired(context);
        } else {
          SnackBarUtils.showError(
            context, 
            message: _userSitesService.errorMessage
          );
        }
      }
    }
  }


  List<Widget> _buildSiteCards() {
    if (_userSitesService.sites.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: ResponsiveUtils.responsivePadding(context),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'No sites assigned',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    // If 3 or fewer sites, show them directly without scrollable container
    if (_userSitesService.sites.length <= 3) {
      return _userSitesService.sites.map((site) => _buildSiteCard(site)).toList();
    }

    // If more than 3 sites, use scrollable container
    return [
      SizedBox(
        height: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 300,
          tablet: 360,
          desktop: 420,
        ),
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: _userSitesService.sites.length,
          itemBuilder: (context, index) {
            return _buildSiteCard(_userSitesService.sites[index]);
          },
        ),
      ),
    ];
  }

  Widget _buildSiteCard(SiteModel site) {
    return Container(
      width: double.infinity,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Site icon
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
              Icons.location_on_outlined,
              color: Theme.of(context).colorScheme.primary,
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
          // Site details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (site.address != null && site.address!.isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 4,
                      tablet: 6,
                      desktop: 8,
                    ),
                  ),
                  Text(
                    site.address!,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
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
          // Status chip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 8,
                tablet: 10,
                desktop: 12,
              ),
              vertical: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 4,
                tablet: 6,
                desktop: 8,
              ),
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(site.status),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 12,
                  tablet: 16,
                  desktop: 20,
                ),
              ),
            ),
            child: Text(
              site.status,
              style: AppTypography.bodySmall.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'overdue':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use fetched user details if available, otherwise use current user
    final UserModel? user = widget.userId != null 
        ? _userDetailService.user 
        : AuthService.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.userId != null ? 'User Profile' : 'My Profile',
        showDrawer: false,
      ),
      body: (_userDetailService.isLoading || _userSitesService.isLoading) && (widget.userId != null || AuthService.currentUser != null)
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                    : RefreshIndicator(
            onRefresh: () async {
              if (widget.userId != null) {
                await Future.wait([
                  _loadUserDetails(),
                  _loadUserSites(),
                ]);
              } else {
                // For current user's profile, only refresh sites
                await _loadUserSites();
              }
            },
            child: SingleChildScrollView(
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
                color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.onPrimary,
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
                color: Theme.of(context).colorScheme.onPrimary,
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
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: ResponsiveUtils.responsivePadding(context),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                        value: user?.designationDisplay ?? 'Employee',
                      ),

                      _buildProfileItem(
                        context,
                        icon: Icons.circle_outlined,
                        title: 'Status',
                        value: user?.status ?? 'N/A',
                        valueColor: user?.isActive == true
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                      _buildProfileItem(
                        context,
                        icon: Icons.calendar_today_outlined,
                        title: 'Joined On',
                        value: _formatDate(user?.createdAt) ?? 'N/A',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15,),
          if (_userSitesService.sites.isNotEmpty || (widget.userId == null && AuthService.currentUser?.siteId != null))  Container(
                  width: double.infinity,
                  padding: ResponsiveUtils.responsivePadding(context),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                        'Assigned Sites',
                        style: AppTypography.titleLarge.copyWith(
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
                        ..._buildSiteCards(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
              color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
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