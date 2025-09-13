import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/session_manager.dart';
import '../core/theme/app_typography.dart';
import '../services/site_service.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/site_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import '../core/utils/validation_utils.dart';
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
                          _buildStatusChip(context, 'All', '', _getStatusCount('', _getSitesForCounting())),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Active', 'Active', _getStatusCount('Active', _getSitesForCounting())),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Pending', 'Pending', _getStatusCount('Pending', _getSitesForCounting())),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Complete', 'Complete', _getStatusCount('Complete', _getSitesForCounting())),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                          _buildStatusChip(context, 'Overdue', 'Overdue', _getStatusCount('Overdue', _getSitesForCounting())),
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

  // Helper method to get filtered sites for counting (without affecting the main filtered list)
  List<SiteModel> _getSitesForCounting() {
    List<SiteModel> sitesToFilter = SiteService.allSites;
    
    // Only apply search filter for counting, not status filter
    if (_searchQuery.isNotEmpty) {
      sitesToFilter = sitesToFilter.where((site) {
        final nameMatch = site.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final clientMatch = site.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return nameMatch || clientMatch;
      }).toList();
    }
    
    return sitesToFilter;
  }

  // Helper method to get status-specific counts from filtered sites
  int _getStatusCount(String status, List<SiteModel> sites) {
    if (status.isEmpty) return sites.length;
    
    if (status.toLowerCase() == 'overdue') {
      // Calculate overdue dynamically based on end date
      return sites.where((site) => SiteService.isSiteOverdue(site)).length;
    }
    
    return sites.where((site) => site.status.toLowerCase() == status.toLowerCase()).length;
  }


  List<SiteModel> _getFilteredSites() {
    List<SiteModel> sitesToFilter = SiteService.allSites;

    // Debug logging
    print('🔍 === SEARCH DEBUG ===');
    print('📊 Total sites: ${sitesToFilter.length}');
    print('🔍 Search query: "$_searchQuery"');
    print('📋 Selected status: "$_selectedStatus"');

    // First filter by status
    if (_selectedStatus.isNotEmpty) {
      sitesToFilter = sitesToFilter.where((site) {
        if (_selectedStatus.toLowerCase() == 'overdue') {
          return SiteService.isSiteOverdue(site);
        }
        return site.status.toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
      print('📊 After status filter: ${sitesToFilter.length} sites');
    }

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      sitesToFilter = sitesToFilter.where((site) {
        final nameMatch = site.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final clientMatch = site.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        
        // Debug individual site matching
        if (nameMatch || clientMatch) {
          print('✅ Site "${site.name}" matches search "$_searchQuery"');
        }
        
        return nameMatch || clientMatch;
      }).toList();
      print('📊 After search filter: ${sitesToFilter.length} sites');
    }

    print('🔍 === END SEARCH DEBUG ===');
    return sitesToFilter;
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



} 