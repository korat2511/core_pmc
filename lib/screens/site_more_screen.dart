import 'package:core_pmc/screens/site_details_screen.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';
import 'manage_user_screen.dart';
import 'site_category_screen.dart';
import 'site_manpower_screen.dart';
import 'site_qc_category_screen.dart';

class SiteMoreScreen extends StatefulWidget {
  final SiteModel site;

  const SiteMoreScreen({super.key, required this.site});

  @override
  State<SiteMoreScreen> createState() => _SiteMoreScreenState();
}

class _SiteMoreScreenState extends State<SiteMoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: _buildOptionsGrid())],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Site Section
          _buildSectionHeader('Site'),
          _buildSectionGrid([
            {
              'title': 'Site Details',
              'icon': Icons.info_outline,
              'color': AppColors.errorColor,
            },
            {
              'title': 'Site Users',
              'icon': Icons.people_outline,
              'color': AppColors.primaryColor,
            },
            {
              'title': 'Manpower',
              'icon': Icons.engineering_outlined,
              'color': AppColors.warningColor,
            },

            {
              'title': 'Site Gallery',
              'icon': Icons.photo_library_outlined,
              'color': AppColors.primaryColor,
            },
            {
              'title': 'Quantity',
              'icon': Icons.assessment_outlined,
              'color': AppColors.infoColor,
            },
          ]),

          SizedBox(height: 24),

          // Tasks Section
          _buildSectionHeader('Tasks'),
          _buildSectionGrid([
            {
              'title': 'Categories',
              'icon': Icons.category_outlined,
              'color': AppColors.primaryColor,
            },
            {
              'title': 'QC Categories',
              'icon': Icons.verified_outlined,
              'color': AppColors.successColor,
            },
            // {'title': 'Tags', 'icon': Icons.label_outlined, 'color': AppColors.secondaryColor},
            {
              'title': 'Issues',
              'icon': Icons.report_problem_outlined,
              'color': AppColors.errorColor,
            },
          ]),

          SizedBox(height: 24),

          // Other Section
          _buildSectionHeader('Other'),
          _buildSectionGrid([
            {
              'title': 'Folders',
              'icon': Icons.folder_outlined,
              'color': AppColors.secondaryColor,
            },
            {
              'title': 'Meetings',
              'icon': Icons.meeting_room_outlined,
              'color': AppColors.successColor,
            },
            {
              'title': 'Vendors',
              'icon': Icons.business_outlined,
              'color': AppColors.infoColor,
            },
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      ),
      child: Text(
        title,
        style: AppTypography.titleLarge.copyWith(
          fontSize: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 18,
            tablet: 20,
            desktop: 22,
          ),
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionGrid(List<Map<String, dynamic>> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return _buildOptionCard(option);
      },
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option) {
    return GestureDetector(
      onTap: () {
        _handleOptionTap(option['title']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          border: Border.all(color: AppColors.borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.textLight.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
                color: option['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 20,
                    tablet: 24,
                    desktop: 28,
                  ),
                ),
              ),
              child: Icon(
                option['icon'],
                color: option['color'],
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 28,
                ),
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
              option['title'],
              style: AppTypography.bodyMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleOptionTap(String optionTitle) {
    print('Tapped on: $optionTitle');

    switch (optionTitle) {
      case 'Site Details':
        NavigationUtils.push(context, SiteDetailsScreen(site: widget.site));
        break;
      case 'Site Users':
        NavigationUtils.push(context, ManageUserScreen(site: widget.site));
        break;
      case 'Categories':
        NavigationUtils.push(context, SiteCategoryScreen(site: widget.site));
        break;
      case 'Manpower':
        NavigationUtils.push(context, SiteManpowerScreen(site: widget.site));
        break;
      case 'QC Categories':
        NavigationUtils.push(context, SiteQcCategoryScreen(site: widget.site));
        break;
      case 'Quantity':
        SnackBarUtils.showInfo(
          context,
          message: 'Quantity functionality coming soon',
        );
        break;
      case 'Tags':
        SnackBarUtils.showInfo(
          context,
          message: 'Tags functionality coming soon',
        );
        break;
      case 'Site Gallery':
        SnackBarUtils.showInfo(
          context,
          message: 'Site Gallery functionality coming soon',
        );
        break;
      case 'Folders':
        Navigator.of(context).pushNamed(
          '/site-albums',
          arguments: {
            'siteId': widget.site.id,
            'siteName': widget.site.name,
          },
        );
        break;
      default:
        // Show a temporary message for other options
        SnackBarUtils.showInfo(
          context,
          message: '$optionTitle functionality coming soon',
        );
    }
  }
}
