import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../services/site_service.dart';
import '../screens/manage_user_screen.dart';
import '../screens/site_details_screen.dart';
import '../screens/site_details_with_bottom_nav.dart';

class SiteCard extends StatefulWidget {
  final SiteModel site;
  final VoidCallback? onTap;
  final Function(SiteModel)? onSiteUpdated;
  final String currentStatus;

  const SiteCard({
    super.key,
    required this.site,
    this.onTap,
    this.onSiteUpdated,
    this.currentStatus = '',
  });

  @override
  State<SiteCard> createState() => _SiteCardState();
}

class _SiteCardState extends State<SiteCard> {
  bool _isPinning = false;

  Color _getStatusColor() {
    switch (widget.site.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'complete':
        return Colors.blue;
      case 'overdue':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    // Dismiss keyboard when menu action is triggered
    FocusScope.of(context).unfocus();
    
    switch (action) {
      case 'details':
        // Navigate to site details screen
        NavigationUtils.push(
          context,
          SiteDetailsScreen(
            site: widget.site,
            onSiteUpdated: widget.onSiteUpdated,
          ),
        );
        break;
      case 'pin':
        _togglePinSite(context);
        break;
      case 'complete':
        // TODO: Mark site as complete
        print('Mark site as complete: ${widget.site.name}');
        break;
      case 'team':
        // Navigate to manage team screen
        NavigationUtils.push(context, ManageUserScreen(site: widget.site));
        break;
      case 'albums':
        // Navigate to site albums screen
        Navigator.of(context).pushNamed(
          '/site-albums',
          arguments: {'siteId': widget.site.id, 'siteName': widget.site.name},
        );
        break;
    }
  }

  Future<void> _togglePinSite(BuildContext context) async {
    if (_isPinning) return; // Prevent multiple calls
    
    setState(() {
      _isPinning = true;
    });
    
    try {
      final success = await SiteService.pinSite(
        widget.site.id,
        currentStatus: widget.currentStatus,
      );
      
      if (success) {
        // Update the local site object
        final updatedSite = widget.site.copyWith(
          isPinned: widget.site.isPinned == 1 ? 0 : 1,
        );
        
        // Notify parent about the update
        widget.onSiteUpdated?.call(updatedSite);
        
        // Show success message
        SnackBarUtils.showSuccess(
          context,
          message: widget.site.isPinned == 1
              ? 'Site unpinned successfully'
              : 'Site pinned successfully',
        );
      } else {
        // Show error message
        SnackBarUtils.showError(context, message: SiteService.errorMessage);
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error pinning/unpinning site: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPinning = false;
        });
      }
    }
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
            Icons.business,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping site card
        FocusScope.of(context).unfocus();
        // Clear any search focus
        FocusManager.instance.primaryFocus?.unfocus();
        // Navigate to site details screen with bottom navigation
        NavigationUtils.push(
          context,
          SiteDetailsWithBottomNav(site: widget.site),
        ).then((_) {
          // When returning from navigation, ensure keyboard is dismissed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).unfocus();
          });
        });
      },
      child: Container(
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
        child: Column(
            children: [
              Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // Site Image (Square thumbnail) - Click to open SiteDetailsScreen
                  GestureDetector(
                    onTap: () {
                      // Dismiss keyboard when tapping site image
                      FocusScope.of(context).unfocus();
                      // Navigate to site details screen (without bottom nav)
                      NavigationUtils.push(
                context,
                        SiteDetailsScreen(
                          site: widget.site,
                          onSiteUpdated: widget.onSiteUpdated,
                        ),
                      ).then((_) {
                        // When returning from navigation, ensure keyboard is dismissed
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).unfocus();
                        });
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
              decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                child: widget.site.hasImages
                    ? Image.network(
                        widget.site.firstImagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder(context);
                        },
                      )
                    : _buildImagePlaceholder(context),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),
                  Expanded(
                    child: Row(
                children: [
                        // Title Section - Flexible width
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              // Site name with overflow protection
                            Text(
                              widget.site.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 15,
                                  color: Theme.of(
                                  context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                              SizedBox(height: 2),
                              Text(
                                'Core PMC',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 8),
                        // Add spacing between title and status

                        // Status and Pin Section - Fixed width
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pin Icon
                            if (widget.site.isPinned == 1)
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Icon(
                                  Icons.push_pin,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 16,
                                ),
                              ),

                            // Status Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.site.status.toUpperCase(),
                          style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                            color: _getStatusColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Menu icon moved back to bottom right
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: AppColors.primaryLight),
              ),

                       Row(
                         children: [
                  // Progress Section
                           Expanded(
                    flex: 1,
                    child: Row(
                               children: [
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4),
                                 Text(
                          '${widget.site.progress}%',
                                   style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            color: Theme.of(
                                       context,
                            ).colorScheme.onSurfaceVariant,
                                   ),
                                 ),
                               ],
                             ),
                           ),

                  // Date Section
                           Expanded(
                    flex: 4,
                    child: Row(
                               children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${widget.site.startDate ?? 'Not set'} - ${widget.site.endDate ?? 'End Date'}',
                                   style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: Theme.of(
                                       context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                               ],
                             ),
                           ),

                  // Menu Button
                           PopupMenuButton<String>(
                    child: Container(
                      height: 30,
                      width: 20,
                      child: Icon(
                               Icons.more_vert,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                    ),

                             onSelected: (value) {
                               _handleMenuAction(context, value);
                             },
                             itemBuilder: (BuildContext context) => [
                               PopupMenuItem<String>(
                                 value: 'details',
                                 child: Row(
                                   children: [
                                     Icon(
                                       Icons.info_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                                       size: 18,
                                     ),
                                     SizedBox(width: 12),
                                     Text(
                                       'Site Details',
                                       style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               PopupMenuItem<String>(
                                 value: 'pin',
                                 child: Row(
                                   children: [
                                     if (_isPinning)
                                       SizedBox(
                                         width: 18,
                                         height: 18,
                                         child: CircularProgressIndicator(
                                           strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                         ),
                                       )
                                     else
                                       Icon(
                                widget.site.isPinned == 1
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                         size: 18,
                                       ),
                                     SizedBox(width: 12),
                                     Text(
                                       _isPinning 
                                         ? 'Processing...' 
                                  : (widget.site.isPinned == 1
                                        ? 'Unpin Site'
                                        : 'Pin Site'),
                                       style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               if (widget.site.progress == 100)
                                 PopupMenuItem<String>(
                                   value: 'complete',
                                   child: Row(
                                     children: [
                                       Icon(
                                         Icons.check_circle_outline,
                                color: Colors.green,
                                         size: 18,
                                       ),
                                       SizedBox(width: 12),
                                       Text(
                                         'Mark as Complete',
                                         style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               PopupMenuItem<String>(
                                 value: 'team',
                                 child: Row(
                                   children: [
                                     Icon(
                                       Icons.people_outline,
                              color: Theme.of(context).colorScheme.primary,
                                       size: 18,
                                     ),
                                     SizedBox(width: 12),
                                     Text(
                                       'Manage Team',
                                       style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               PopupMenuItem<String>(
                                 value: 'albums',
                                 child: Row(
                                   children: [
                                     Icon(
                                       Icons.folder_outlined,
                              color: Colors.orange,
                                       size: 18,
                                     ),
                                     SizedBox(width: 12),
                                     Text(
                                       'View Albums',
                                       style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ],
                   ),
        ),
      ),
    );
  }
} 
