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
            icon: Icon(Icons.fingerprint, color: Colors.white),
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
      drawer: const CustomDrawer(),
      floatingActionButton: ValidationUtils.canCreateSite(context)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed('/create-site');
              },
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.textWhite,
              icon: Icon(Icons.add),
              label: Text('Create Site'),
            )
          : null,
      body: DismissKeyboard(
        child: RefreshIndicator(
          onRefresh: _loadSites,
          color: AppColors.primaryColor,
          child: CustomScrollView(
          slivers: [
            // Sliver App Bar with Search and Status Dropdown
            // SliverAppBar(
            //   expandedHeight: ResponsiveUtils.responsiveFontSize(
            //     context,
            //     mobile: 140,
            //     tablet: 160,
            //     desktop: 180,
            //   ),
            //   floating: true,
            //   pinned: true,
            //   backgroundColor: AppColors.surfaceColor,
            //   elevation: 0,
            //   title: Row(
            //     children: [
            //       // Search Bar in App Bar (Collapsed State)
            //       Expanded(
            //         flex: 2,
            //         child: Container(
            //           height: ResponsiveUtils.responsiveFontSize(
            //             context,
            //             mobile: 35,
            //             tablet: 40,
            //             desktop: 45,
            //           ),
            //           padding: EdgeInsets.symmetric(
            //             horizontal: ResponsiveUtils.responsiveSpacing(
            //               context,
            //               mobile: 8,
            //               tablet: 12,
            //               desktop: 16,
            //             ),
            //           ),
            //           decoration: BoxDecoration(
            //             color: AppColors.textWhite,
            //             borderRadius: BorderRadius.circular(
            //               ResponsiveUtils.responsiveSpacing(
            //                 context,
            //                 mobile: 6,
            //                 tablet: 8,
            //                 desktop: 10,
            //               ),
            //             ),
            //             border: Border.all(
            //               color: AppColors.borderColor,
            //               width: 1,
            //             ),
            //           ),
            //           child: TextField(
            //             onChanged: (value) {
            //               setState(() {
            //                 _searchQuery = value;
            //               });
            //             },
            //             decoration: InputDecoration(
            //               hintText: 'Search sites...',
            //               prefixIcon: Icon(
            //                 Icons.search,
            //                 color: AppColors.textSecondary,
            //                 size: ResponsiveUtils.responsiveFontSize(
            //                   context,
            //                   mobile: 16,
            //                   tablet: 18,
            //                   desktop: 20,
            //                 ),
            //               ),
            //               border: InputBorder.none,
            //               contentPadding: EdgeInsets.zero,
            //             ),
            //           ),
            //         ),
            //       ),
            //       SizedBox(
            //         width: ResponsiveUtils.responsiveSpacing(
            //           context,
            //           mobile: 8,
            //           tablet: 12,
            //           desktop: 16,
            //         ),
            //       ),
            //       // Status Dropdown in App Bar (Collapsed State)
            //       Expanded(
            //         flex: 1,
            //         child: Container(
            //           height: ResponsiveUtils.responsiveFontSize(
            //             context,
            //             mobile: 35,
            //             tablet: 40,
            //             desktop: 45,
            //           ),
            //           padding: EdgeInsets.symmetric(
            //             horizontal: ResponsiveUtils.responsiveSpacing(
            //               context,
            //               mobile: 6,
            //               tablet: 8,
            //               desktop: 10,
            //             ),
            //           ),
            //           decoration: BoxDecoration(
            //             color: AppColors.textWhite,
            //             borderRadius: BorderRadius.circular(
            //               ResponsiveUtils.responsiveSpacing(
            //                 context,
            //                 mobile: 6,
            //                 tablet: 8,
            //                 desktop: 10,
            //               ),
            //             ),
            //             border: Border.all(
            //               color: AppColors.borderColor,
            //               width: 1,
            //             ),
            //           ),
            //           child: DropdownButtonHideUnderline(
            //             child: DropdownButton<String>(
            //               value: _selectedStatus.isEmpty ? 'All' : _selectedStatus,
            //               isExpanded: true,
            //               icon: Icon(
            //                 Icons.keyboard_arrow_down,
            //                 color: AppColors.textSecondary,
            //                 size: ResponsiveUtils.responsiveFontSize(
            //                   context,
            //                   mobile: 14,
            //                   tablet: 16,
            //                   desktop: 18,
            //                 ),
            //               ),
            //               items: [
            //                 DropdownMenuItem(
            //                   value: 'All',
            //                   child: Text(
            //                     'All',
            //                     style: AppTypography.bodyMedium.copyWith(
            //                       fontSize: ResponsiveUtils.responsiveFontSize(
            //                         context,
            //                         mobile: 10,
            //                         tablet: 12,
            //                         desktop: 14,
            //                       ),
            //                       color: AppColors.textPrimary,
            //                     ),
            //                     overflow: TextOverflow.ellipsis,
            //                   ),
            //                 ),
            //                 DropdownMenuItem(
            //                   value: 'Active',
            //                   child: Text(
            //                     'Active',
            //                     style: AppTypography.bodyMedium.copyWith(
            //                       fontSize: ResponsiveUtils.responsiveFontSize(
            //                         context,
            //                         mobile: 10,
            //                         tablet: 12,
            //                         desktop: 14,
            //                       ),
            //                       color: AppColors.textPrimary,
            //                     ),
            //                     overflow: TextOverflow.ellipsis,
            //                   ),
            //                 ),
            //                 DropdownMenuItem(
            //                   value: 'Pending',
            //                   child: Text(
            //                     'Pending',
            //                     style: AppTypography.bodyMedium.copyWith(
            //                       fontSize: ResponsiveUtils.responsiveFontSize(
            //                         context,
            //                         mobile: 10,
            //                         tablet: 12,
            //                         desktop: 14,
            //                       ),
            //                       color: AppColors.textPrimary,
            //                     ),
            //                     overflow: TextOverflow.ellipsis,
            //                   ),
            //                 ),
            //                 DropdownMenuItem(
            //                   value: 'Complete',
            //                   child: Text(
            //                     'Complete',
            //                     style: AppTypography.bodyMedium.copyWith(
            //                       fontSize: ResponsiveUtils.responsiveFontSize(
            //                         context,
            //                         mobile: 10,
            //                         tablet: 12,
            //                         desktop: 14,
            //                       ),
            //                       color: AppColors.textPrimary,
            //                     ),
            //                     overflow: TextOverflow.ellipsis,
            //                   ),
            //                 ),
            //                 DropdownMenuItem(
            //                   value: 'Overdue',
            //                   child: Text(
            //                     'Overdue',
            //                     style: AppTypography.bodyMedium.copyWith(
            //                       fontSize: ResponsiveUtils.responsiveFontSize(
            //                         context,
            //                         mobile: 10,
            //                         tablet: 12,
            //                         desktop: 14,
            //                       ),
            //                       color: AppColors.textPrimary,
            //                     ),
            //                     overflow: TextOverflow.ellipsis,
            //                   ),
            //                 ),
            //               ],
            //               onChanged: (String? newValue) {
            //                 setState(() {
            //                   _selectedStatus = newValue == 'All' ? '' : (newValue ?? '');
            //                 });
            //                 _loadSites();
            //               },
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            //   flexibleSpace: FlexibleSpaceBar(
            //     background: Container(
            //       padding: ResponsiveUtils.responsivePadding(context),
            //       child: Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           // Search Bar (Expanded State)
            //           Container(
            //             width: double.infinity,
            //             height: ResponsiveUtils.responsiveFontSize(
            //               context,
            //               mobile: 45,
            //               tablet: 50,
            //               desktop: 55,
            //             ),
            //             padding: EdgeInsets.symmetric(
            //               horizontal: ResponsiveUtils.responsiveSpacing(
            //                 context,
            //                 mobile: 12,
            //                 tablet: 16,
            //                 desktop: 20,
            //               ),
            //             ),
            //             decoration: BoxDecoration(
            //               color: AppColors.textWhite,
            //               borderRadius: BorderRadius.circular(
            //                 ResponsiveUtils.responsiveSpacing(
            //                   context,
            //                   mobile: 8,
            //                   tablet: 12,
            //                   desktop: 16,
            //                 ),
            //               ),
            //               border: Border.all(
            //                 color: AppColors.borderColor,
            //                 width: 1,
            //               ),
            //             ),
            //             child: TextField(
            //               onChanged: (value) {
            //                 setState(() {
            //                   _searchQuery = value;
            //                 });
            //               },
            //               decoration: InputDecoration(
            //                 hintText: 'Search sites...',
            //                 prefixIcon: Icon(
            //                   Icons.search,
            //                   color: AppColors.textSecondary,
            //                   size: ResponsiveUtils.responsiveFontSize(
            //                     context,
            //                     mobile: 18,
            //                     tablet: 20,
            //                     desktop: 22,
            //                   ),
            //                 ),
            //                 border: InputBorder.none,
            //                 contentPadding: EdgeInsets.zero,
            //               ),
            //             ),
            //           ),
            //           SizedBox(
            //             height: ResponsiveUtils.responsiveSpacing(
            //               context,
            //               mobile: 12,
            //               tablet: 16,
            //               desktop: 20,
            //             ),
            //           ),
            //           // Status Dropdown (Expanded State)
            //           Container(
            //             width: double.infinity,
            //             height: ResponsiveUtils.responsiveFontSize(
            //               context,
            //               mobile: 45,
            //               tablet: 50,
            //               desktop: 55,
            //             ),
            //             padding: EdgeInsets.symmetric(
            //               horizontal: ResponsiveUtils.responsiveSpacing(
            //                 context,
            //                 mobile: 12,
            //                 tablet: 16,
            //                 desktop: 20,
            //               ),
            //             ),
            //             decoration: BoxDecoration(
            //               color: AppColors.textWhite,
            //               borderRadius: BorderRadius.circular(
            //                 ResponsiveUtils.responsiveSpacing(
            //                   context,
            //                   mobile: 8,
            //                   tablet: 12,
            //                   desktop: 16,
            //                 ),
            //               ),
            //               border: Border.all(
            //                 color: AppColors.borderColor,
            //                 width: 1,
            //               ),
            //             ),
            //             child: DropdownButtonHideUnderline(
            //               child: DropdownButton<String>(
            //                 value: _selectedStatus.isEmpty ? 'All' : _selectedStatus,
            //                 isExpanded: true,
            //                 icon: Icon(
            //                   Icons.keyboard_arrow_down,
            //                   color: AppColors.textSecondary,
            //                   size: ResponsiveUtils.responsiveFontSize(
            //                     context,
            //                     mobile: 16,
            //                     tablet: 18,
            //                     desktop: 20,
            //                   ),
            //                 ),
            //                 items: [
            //                   DropdownMenuItem(
            //                     value: 'All',
            //                     child: Text(
            //                       'All',
            //                       style: AppTypography.bodyMedium.copyWith(
            //                         fontSize: ResponsiveUtils.responsiveFontSize(
            //                           context,
            //                           mobile: 12,
            //                           tablet: 14,
            //                           desktop: 16,
            //                         ),
            //                         color: AppColors.textPrimary,
            //                       ),
            //                       overflow: TextOverflow.ellipsis,
            //                     ),
            //                   ),
            //                   DropdownMenuItem(
            //                     value: 'Active',
            //                     child: Text(
            //                       'Active',
            //                       style: AppTypography.bodyMedium.copyWith(
            //                         fontSize: ResponsiveUtils.responsiveFontSize(
            //                           context,
            //                           mobile: 12,
            //                           tablet: 14,
            //                           desktop: 16,
            //                         ),
            //                         color: AppColors.textPrimary,
            //                       ),
            //                       overflow: TextOverflow.ellipsis,
            //                     ),
            //                   ),
            //                   DropdownMenuItem(
            //                     value: 'Pending',
            //                     child: Text(
            //                       'Pending',
            //                       style: AppTypography.bodyMedium.copyWith(
            //                         fontSize: ResponsiveUtils.responsiveFontSize(
            //                           context,
            //                           mobile: 12,
            //                           tablet: 14,
            //                           desktop: 16,
            //                         ),
            //                         color: AppColors.textPrimary,
            //                       ),
            //                       overflow: TextOverflow.ellipsis,
            //                     ),
            //                   ),
            //                   DropdownMenuItem(
            //                     value: 'Complete',
            //                     child: Text(
            //                       'Complete',
            //                       style: AppTypography.bodyMedium.copyWith(
            //                         fontSize: ResponsiveUtils.responsiveFontSize(
            //                           context,
            //                           mobile: 12,
            //                           tablet: 14,
            //                           desktop: 16,
            //                         ),
            //                         color: AppColors.textPrimary,
            //                       ),
            //                       overflow: TextOverflow.ellipsis,
            //                     ),
            //                   ),
            //                   DropdownMenuItem(
            //                     value: 'Overdue',
            //                     child: Text(
            //                       'Overdue',
            //                       style: AppTypography.bodyMedium.copyWith(
            //                         fontSize: ResponsiveUtils.responsiveFontSize(
            //                           context,
            //                           mobile: 12,
            //                           tablet: 14,
            //                           desktop: 16,
            //                         ),
            //                         color: AppColors.textPrimary,
            //                       ),
            //                       overflow: TextOverflow.ellipsis,
            //                     ),
            //                   ),
            //                 ],
            //                 onChanged: (String? newValue) {
            //                   setState(() {
            //                     _selectedStatus = newValue == 'All' ? '' : (newValue ?? '');
            //                   });
            //                   _loadSites();
            //                 },
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
                        // Search Bar
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
                          color: AppColors.primaryColor,
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
                              'No sites found',
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
          color: isSelected ? AppColors.primaryColor : AppColors.surfaceColor,
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
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
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
      backgroundColor: AppColors.surfaceColor,
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      labelStyle: AppTypography.bodyMedium.copyWith(
        fontSize: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 12,
          tablet: 14,
          desktop: 16,
        ),
        color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
        width: 1,
      ),
    );
  }
} 