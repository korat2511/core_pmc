import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
        color: AppColors.surfaceColor,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.textLight.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: ResponsiveUtils.responsivePadding(context),
        leading: Container(
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
            color: AppColors.primaryColor.withOpacity(0.1),
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
            Icons.category_outlined,
            color: AppColors.primaryColor,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
          ),
        ),
        title: Text(
          category.name,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'ID: ${category.id}',
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
            SizedBox(height: 2),
            Text(
              'Sub Category ID: ${category.catSubId}',
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
            if (!category.isEditable) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 6,
                    tablet: 8,
                    desktop: 10,
                  ),
                  vertical: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 2,
                    tablet: 3,
                    desktop: 4,
                  ),
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 4,
                      tablet: 6,
                      desktop: 8,
                    ),
                  ),
                ),
                child: Text(
                  'System Category',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                    color: AppColors.warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: category.isEditable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 6,
                          tablet: 8,
                          desktop: 10,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 6,
                            tablet: 8,
                            desktop: 10,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryColor,
                        size: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                  ),
                  // Delete Button
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 6,
                          tablet: 8,
                          desktop: 10,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 6,
                            tablet: 8,
                            desktop: 10,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: AppColors.errorColor,
                        size: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
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
                  color: AppColors.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 6,
                      tablet: 8,
                      desktop: 10,
                    ),
                  ),
                ),
                child: Text(
                  'Read Only',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 10,
                      tablet: 12,
                      desktop: 14,
                    ),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }
}
