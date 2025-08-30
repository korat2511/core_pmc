import 'package:core_pmc/screens/site_album_screen.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';
import 'site_chat_screen.dart';
import 'site_report_screen.dart';
import 'site_tasks_screen.dart';
import 'site_material_screen.dart';
import 'site_more_screen.dart';

class SiteDetailsWithBottomNav extends StatefulWidget {
  final SiteModel site;

  const SiteDetailsWithBottomNav({super.key, required this.site});

  @override
  State<SiteDetailsWithBottomNav> createState() =>
      _SiteDetailsWithBottomNavState();
}

class _SiteDetailsWithBottomNavState extends State<SiteDetailsWithBottomNav> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onProfilePressed: () {
          NavigationUtils.push(
            context,
            SiteAlbumScreen(siteId: widget.site.id, siteName: widget.site.name),
          );
        },
        title: widget.site.name,
        showDrawer: false,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SiteChatScreen(site: widget.site);
      case 1:
        return SiteReportScreen(site: widget.site);
      case 2:
        return SiteTasksScreen(site: widget.site);
      case 3:
        return SiteMaterialScreen(site: widget.site);
      case 4:
        return SiteMoreScreen(site: widget.site);
      default:
        return SiteChatScreen(site: widget.site);
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        height: ResponsiveUtils.responsiveFontSize(
          context,
          mobile: 70,
          tablet: 80,
          desktop: 90,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 8,
            tablet: 12,
            desktop: 16,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(0, Icons.chat_bubble_outline, 'Chat'),
            _buildBottomNavItem(1, Icons.assessment_outlined, 'Report'),
            _buildBottomNavItem(2, Icons.task_outlined, 'Tasks'),
            _buildBottomNavItem(3, Icons.inventory_2_outlined, 'Material'),
            _buildBottomNavItem(4, Icons.more_horiz, 'More'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
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
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
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
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
