import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../widgets/custom_text_field.dart';

class CategoryModal extends StatefulWidget {
  final SiteModel site;
  final CategoryModel? category;
  final VoidCallback? onCategoryCreated;
  final VoidCallback? onCategoryUpdated;

  const CategoryModal({
    super.key,
    required this.site,
    this.category,
    this.onCategoryCreated,
    this.onCategoryUpdated,
  });

  @override
  State<CategoryModal> createState() => _CategoryModalState();
}

class _CategoryModalState extends State<CategoryModal> {
  final TextEditingController _nameController = TextEditingController();
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.category != null;
    if (_isEditMode) {
      _nameController.text = widget.category!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Please enter a category name',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      
      if (_isEditMode) {
        success = await _categoryService.updateCategory(
          categoryId: widget.category!.id,
          name: name,
          siteId: widget.site.id,
        );
      } else {
        success = await _categoryService.createCategory(
          siteId: widget.site.id,
          name: name,
        );
      }

      if (success && mounted) {
        SnackBarUtils.showSuccess(
          context,
          message: _isEditMode 
              ? 'Category updated successfully' 
              : 'Category created successfully',
        );
        
        if (_isEditMode) {
          widget.onCategoryUpdated?.call();
        } else {
          widget.onCategoryCreated?.call();
        }
        
        Navigator.pop(context);
      } else if (mounted) {
        SnackBarUtils.showError(
          context,
          message: _categoryService.errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Failed to ${_isEditMode ? 'update' : 'create'} category: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: AppColors.primaryColor,
                  size: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
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
                        _isEditMode ? 'Edit Category' : 'Add Category',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.site.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Form
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Category Name',
                  hintText: 'Enter category name',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                            height: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                            ),
                          )
                        : Text(
                            _isEditMode ? 'Update Category' : 'Create Category',
                            style: AppTypography.bodyLarge.copyWith(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
        ],
      ),
    );
  }
}
