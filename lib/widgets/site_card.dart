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
import 'dismiss_keyboard.dart';

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
        return AppColors.successColor;
      case 'pending':
        return AppColors.warningColor;
      case 'complete':
        return AppColors.infoColor;
      case 'overdue':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }


  void _handleMenuAction(BuildContext context, String action) {
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
        NavigationUtils.push(
          context,
          ManageUserScreen(site: widget.site),
        );
        break;
      case 'albums':
        // Navigate to site albums screen
        Navigator.of(context).pushNamed(
          '/site-albums',
          arguments: {
            'siteId': widget.site.id,
            'siteName': widget.site.name,
          },
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
      final success = await SiteService.pinSite(widget.site.id, currentStatus: widget.currentStatus);
      
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
          message: widget.site.isPinned == 1 ? 'Site unpinned successfully' : 'Site pinned successfully',
        );
      } else {
        // Show error message
        SnackBarUtils.showError(
          context,
          message: SiteService.errorMessage,
        );
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
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          topRight: Radius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            color: AppColors.textSecondary,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 50,
              desktop: 60,
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          Text(
            'No Image',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        decoration: BoxDecoration(
          color: AppColors.textWhite,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Site Image
            Container(
              width: double.infinity,
              height: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 120,
                tablet: 140,
                desktop: 160,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),
                  topRight: Radius.circular(
                    ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),
                  topRight: Radius.circular(
                    ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),
                ),
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

            // Site Content
            Padding(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.site.name,
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                          vertical: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 4,
                            tablet: 6,
                            desktop: 8,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
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
                          widget.site.status.toUpperCase(),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 10,
                              tablet: 12,
                              desktop: 14,
                            ),
                            color: _getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10,),
                      if (widget.site.isPinned == 1)
                        Container(
                          padding: EdgeInsets.all(
                            ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 4,
                              tablet: 6,
                              desktop: 8,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.responsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 12,
                                desktop: 16,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.push_pin,
                            color: AppColors.primaryColor,
                            size: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                        ),


                    ],
                  ),

                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                  ),

                                     // Progress and Dates Section
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Progress Row
                       Row(
                         children: [
                           Text(
                             'Progress',
                             style: AppTypography.bodyMedium.copyWith(
                               fontSize: ResponsiveUtils.responsiveFontSize(
                                 context,
                                 mobile: 12,
                                 tablet: 14,
                                 desktop: 16,
                               ),
                               color: AppColors.textSecondary,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                           const Spacer(),
                           Text(
                             '${widget.site.progress}%',
                             style: AppTypography.bodyLarge.copyWith(
                               fontSize: ResponsiveUtils.responsiveFontSize(
                                 context,
                                 mobile: 14,
                                 tablet: 16,
                                 desktop: 18,
                               ),
                               color: AppColors.textPrimary,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                       ),
                       SizedBox(
                         height: ResponsiveUtils.responsiveSpacing(
                           context,
                           mobile: 8,
                           tablet: 12,
                           desktop: 16,
                         ),
                       ),
                       LinearProgressIndicator(
                         value: widget.site.progress / 100,
                         backgroundColor: AppColors.surfaceColor,
                         valueColor: AlwaysStoppedAnimation<Color>(
                           _getStatusColor(),
                         ),
                         minHeight: ResponsiveUtils.responsiveFontSize(
                           context,
                           mobile: 6,
                           tablet: 8,
                           desktop: 10,
                         ),
                       ),
                       SizedBox(
                         height: ResponsiveUtils.responsiveSpacing(
                           context,
                           mobile: 12,
                           tablet: 16,
                           desktop: 20,
                         ),
                       ),
                       // Dates Row
                       Row(
                         children: [
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Start Date',
                                   style: AppTypography.bodySmall.copyWith(
                                     fontSize: ResponsiveUtils.responsiveFontSize(
                                       context,
                                       mobile: 10,
                                       tablet: 12,
                                       desktop: 14,
                                     ),
                                     color: AppColors.textSecondary,
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
                                   widget.site.startDate ?? 'Not set',
                                   style: AppTypography.bodyMedium.copyWith(
                                     fontSize: ResponsiveUtils.responsiveFontSize(
                                       context,
                                       mobile: 12,
                                       tablet: 14,
                                       desktop: 16,
                                     ),
                                     color: AppColors.textPrimary,
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'End Date',
                                   style: AppTypography.bodySmall.copyWith(
                                     fontSize: ResponsiveUtils.responsiveFontSize(
                                       context,
                                       mobile: 10,
                                       tablet: 12,
                                       desktop: 14,
                                     ),
                                     color: AppColors.textSecondary,
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
                                   widget.site.endDate ?? 'Not set',
                                   style: AppTypography.bodyMedium.copyWith(
                                     fontSize: ResponsiveUtils.responsiveFontSize(
                                       context,
                                       mobile: 12,
                                       tablet: 14,
                                       desktop: 16,
                                     ),
                                     color: AppColors.textPrimary,
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           PopupMenuButton<String>(
                             icon: Icon(
                               Icons.more_vert,
                               color: AppColors.textSecondary,
                               size: ResponsiveUtils.responsiveFontSize(
                                 context,
                                 mobile: 20,
                                 tablet: 22,
                                 desktop: 24,
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
                                       color: AppColors.textSecondary,
                                       size: 18,
                                     ),
                                     SizedBox(width: 12),
                                     Text(
                                       'Site Details',
                                       style: AppTypography.bodyMedium.copyWith(
                                         color: AppColors.textPrimary,
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
                                           color: AppColors.primaryColor,
                                         ),
                                       )
                                     else
                                       Icon(
                                         widget.site.isPinned == 1 ? Icons.push_pin : Icons.push_pin_outlined,
                                         color: AppColors.primaryColor,
                                         size: 18,
                                       ),
                                     SizedBox(width: 12),
                                     Text(
                                       _isPinning
                                         ? 'Processing...'
                                         : (widget.site.isPinned == 1 ? 'Unpin Site' : 'Pin Site'),
                                       style: AppTypography.bodyMedium.copyWith(
                                         color: AppColors.textPrimary,
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
                                         color: AppColors.successColor,
                                         size: 18,
                                       ),
                                       SizedBox(width: 12),
                                       Text(
                                         'Mark as Complete',
                                         style: AppTypography.bodyMedium.copyWith(
                                           color: AppColors.textPrimary,
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
                                       color: AppColors.infoColor,
                                       size: 18,
                                     ),
                                     SizedBox(width: 12),
                                     Text(
                                       'Manage Team',
                                       style: AppTypography.bodyMedium.copyWith(
                                         color: AppColors.textPrimary,
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
                                       color: AppColors.warningColor,
                                       size: 18,
                                     ),
                                     SizedBox(width: 12),
                                     Text(
                                       'View Albums',
                                       style: AppTypography.bodyMedium.copyWith(
                                         color: AppColors.textPrimary,
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

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 