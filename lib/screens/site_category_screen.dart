import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';

import '../models/site_model.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import '../widgets/category_card.dart';
import '../widgets/category_modal.dart';

class SiteCategoryScreen extends StatefulWidget {
  final SiteModel site;

  const SiteCategoryScreen({
    super.key,
    required this.site,
  });

  @override
  State<SiteCategoryScreen> createState() => _SiteCategoryScreenState();
}

class _SiteCategoryScreenState extends State<SiteCategoryScreen> {
  String _searchQuery = '';
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final success = await _categoryService.getCategoriesBySite(
      siteId: widget.site.id,
    );

    if (mounted) {
      setState(() {
        // Trigger UI update
      });
      
      if (!success) {
        SnackBarUtils.showError(
          context,
          message: _categoryService.errorMessage,
        );
      }
    }
  }

  List<CategoryModel> _getFilteredCategories() {
    List<CategoryModel> filteredCategories = _categoryService.categories;

    // Filter by search query (local filtering)
    if (_searchQuery.isNotEmpty) {
      filteredCategories = filteredCategories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredCategories;
  }

  void _handleAddCategory() {
    _showCategoryModal();
  }

  void _handleEditCategory(CategoryModel category) {
    _showCategoryModal(category: category);
  }

  void _handleDeleteCategory(CategoryModel category) {
    _showDeleteConfirmation(category);
  }

  void _showDeleteConfirmation(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Category',
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            child: Text(
              'Delete',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final success = await _categoryService.deleteCategory(
      categoryId: category.id,
      siteId: widget.site.id,
    );

    if (success && mounted) {
      SnackBarUtils.showSuccess(
        context,
        message: 'Category deleted successfully',
      );
      setState(() {});
    } else if (mounted) {
      SnackBarUtils.showError(
        context,
        message: _categoryService.errorMessage,
      );
    }
  }

  void _showCategoryModal({CategoryModel? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CategoryModal(
          site: widget.site,
          category: category,
          onCategoryCreated: () {
            _loadCategories();
          },
          onCategoryUpdated: () {
            _loadCategories();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getFilteredCategories();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Categories',
        showDrawer: false,
        showBackButton: true,
      ),
      body: DismissKeyboard(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: ResponsiveUtils.responsivePadding(context),
              child: CustomSearchBar(
                hintText: 'Search categories...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Category Count
            Padding(
              padding: ResponsiveUtils.horizontalPadding(context),
              child: Row(
                children: [
                  Text(
                    '${filteredCategories.length} Categories',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _handleAddCategory,
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
                          mobile: 8,
                          tablet: 10,
                          desktop: 12,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 4,
                              tablet: 6,
                              desktop: 8,
                            ),
                          ),
                          Text(
                            'Add Category',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            // Categories List
            Expanded(
              child: _categoryService.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : filteredCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
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
                                _searchQuery.isNotEmpty
                                    ? 'No categories found matching your search'
                                    : 'No categories available for this site',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 16,
                                    tablet: 18,
                                    desktop: 20,
                                  ),
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          color: Theme.of(context).colorScheme.primary,
                          child: ListView.builder(
                            padding: ResponsiveUtils.horizontalPadding(context),
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              return CategoryCard(
                                category: category,
                                onEdit: () => _handleEditCategory(category),
                                onDelete: () => _handleDeleteCategory(category),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
