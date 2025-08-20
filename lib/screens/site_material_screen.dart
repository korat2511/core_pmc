import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';

class SiteMaterialScreen extends StatefulWidget {
  final SiteModel site;

  const SiteMaterialScreen({
    super.key,
    required this.site,
  });

  @override
  State<SiteMaterialScreen> createState() => _SiteMaterialScreenState();
}

class _SiteMaterialScreenState extends State<SiteMaterialScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Materials - ${widget.site.name}',
        showDrawer: false,
      ),
      body: Container(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Materials',
              style: AppTypography.titleLarge.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
                color: AppColors.textPrimary,
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 64,
                        tablet: 80,
                        desktop: 96,
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
                      'Materials functionality coming soon',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
