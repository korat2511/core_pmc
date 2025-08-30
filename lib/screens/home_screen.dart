import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/session_manager.dart';
import '../core/theme/app_typography.dart';
import '../services/auth_service.dart';
import '../services/site_service.dart';
import '../models/user_model.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/attendance_card.dart';
import '../widgets/site_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import '../core/utils/validation_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../widgets/custom_button.dart';
import '../screens/attendance_check_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedStatus = '';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
    });

    // Always load all sites first
    final success = await SiteService.getSiteList(status: '');

    if (success) {
      // Then apply status filter if any
      SiteService.updateFilteredSites(_selectedStatus);
    }

    setState(() {
      _isLoading = false;
    });

    if (!success && mounted) {
      // Check for session expiration
      if (SiteService.errorMessage.contains('Session expired')) {
        await SessionManager.handleSessionExpired(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: SiteService.errorMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = AuthService.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Home',
        actions: [
          IconButton(
            icon: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AttendanceCheckScreen(),
                ),
              );
            },
            tooltip: 'Attendance',
          ),
        ],
      ),
      drawer: CustomDrawer(),
      floatingActionButton: ValidationUtils.canCreateSite(context)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed('/create-site');
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: Icon(Icons.add),
              label: Text('Create Site'),
            )
          : null,
      body: DismissKeyboard(
        child: RefreshIndicator(
          onRefresh: _loadSites,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: CustomSearchBar(
                  hintText: 'Search sites...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            // Status Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding:EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip(context, 'All', '', SiteService.allSites.length),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Active', 'Active', SiteService.getActiveSites().length),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Pending', 'Pending', SiteService.getPendingSites().length),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Complete', 'Complete', SiteService.getCompleteSites().length),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Overdue', 'Overdue', SiteService.getOverdueSites().length),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
            
            // Quick Actions Section
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding: ResponsiveUtils.responsivePadding(context),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           'Quick Actions',
            //           style: AppTypography.titleMedium.copyWith(
            //             fontSize: ResponsiveUtils.responsiveFontSize(
            //               context,
            //               mobile: 18,
            //               tablet: 20,
            //               desktop: 22,
            //             ),
            //             color: AppColors.textPrimary,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //         SizedBox(
            //           height: ResponsiveUtils.responsiveSpacing(
            //             context,
            //             mobile: 12,
            //             tablet: 16,
            //             desktop: 20,
            //           ),
            //         ),
            //         AttendanceCard(),
            //       ],
            //     ),
            //   ),
            // ),
            
            // Sites List
            SliverPadding(
              padding: ResponsiveUtils.responsivePadding(context),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 40,
                            tablet: 50,
                            desktop: 60,
                          ),
                        ),
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else if (SiteService.sites.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 40,
                            tablet: 50,
                            desktop: 60,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business,
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
                              'No sites found',
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
                      ),
                    )
                  else
                    ..._getFilteredSites().map((site) => SiteCard(
                      site: site,
                      onTap: () {
                        // TODO: Navigate to site details
                      },
                      onSiteUpdated: _updateSite,
                      currentStatus: _selectedStatus,
                    )),
                ]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _updateSite(SiteModel updatedSite) {
    // Update the site in SiteService
    SiteService.updateSite(updatedSite);
    
    // Re-apply current filter to maintain sorting
    SiteService.updateFilteredSites(_selectedStatus);
    
    // Trigger UI rebuild
    setState(() {});
  }

  List<SiteModel> _getFilteredSites() {
    List<SiteModel> filteredSites = SiteService.sites;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredSites = filteredSites.where((site) {
        return site.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (site.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return filteredSites;
  }

  Widget _buildStatusChip(BuildContext context, String label, String status, int count) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _selectedStatus = isSelected ? '' : status;
        });
        // Update filtered sites without reloading from API
        SiteService.updateFilteredSites(_selectedStatus);
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
            mobile: 4,
            tablet: 6,
            desktop: 8,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }



  Widget _buildFilterChip(BuildContext context, String label, String status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : '';
        });
        _loadSites();
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      labelStyle: AppTypography.bodyMedium.copyWith(
        fontSize: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 12,
          tablet: 14,
          desktop: 16,
        ),
        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
        width: 1,
      ),
    );
  }
} 