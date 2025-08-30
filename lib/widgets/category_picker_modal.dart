import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import 'custom_search_bar.dart';

class CategoryPickerModal extends StatefulWidget {
  final List<CategoryModel> categories;
  final int siteId;

  const CategoryPickerModal({
    super.key,
    required this.categories,
    required this.siteId,
  });

  @override
  State<CategoryPickerModal> createState() => _CategoryPickerModalState();
}

class _CategoryPickerModalState extends State<CategoryPickerModal> {
  String _searchQuery = '';
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = false;
  final _addCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
  }

  @override
  void dispose() {
    _addCategoryController.dispose();
    super.dispose();
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addNewCategory() async {
    if (_addCategoryController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter category name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = CategoryService();
      final success = await categoryService.createCategory(
        siteId: widget.siteId,
        name: _addCategoryController.text.trim(),
      );

      if (success) {
        // Get the newly created category
        final newCategory = categoryService.categories.last;
        
        // Close the modal and return the new category
        Navigator.pop(context, newCategory);
      } else {
        SnackBarUtils.showError(
          context,
          message: categoryService.errorMessage,
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error creating category: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Category'),
        content: TextField(
          controller: _addCategoryController,
          decoration: InputDecoration(
            hintText: 'Enter category name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addCategoryController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addNewCategory();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: Theme.of(context).colorScheme.primary,
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
                  child: Text(
                    'Select Category',
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 20,
                        tablet: 22,
                        desktop: 24,
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                                          child: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                    ),
                  ),
                ),
              ],
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

          // Search Bar
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: CustomSearchBar(
              hintText: 'Search categories...',
              onChanged: _filterCategories,
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

          // Category Count
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: Row(
              children: [
                Text(
                  '${_filteredCategories.length} Categories',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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

          // Categories List
          Expanded(
            child: ListView(
              padding: ResponsiveUtils.horizontalPadding(context),
              children: [
                // Add New Category Option - Always shown at top
                Container(
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
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      _searchQuery.isNotEmpty 
                          ? 'Add "${_searchQuery}" as new category'
                          : 'Add new category',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      if (_searchQuery.isNotEmpty) {
                        _addCategoryController.text = _searchQuery;
                        _addNewCategory();
                      } else {
                        // Show dialog to enter category name
                        _showAddCategoryDialog();
                      }
                    },
                  ),
                ),
                
                // Existing Categories
                if (_filteredCategories.isNotEmpty) ...[
                  ..._filteredCategories.map((category) => _buildCategoryCard(category)),
                ] else ...[
                  // Empty state when no categories found
                  Container(
                    margin: EdgeInsets.only(
                      top: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 20,
                        tablet: 24,
                        desktop: 28,
                      ),
                    ),
                    child: Column(
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
                          _searchQuery.isEmpty
                              ? 'No categories available'
                              : 'No categories found',
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
                        if (_searchQuery.isNotEmpty)
                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 12,
                              desktop: 16,
                            ),
                          ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            'Try a different search term',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(

        title: Text(
          category.name,
          style: AppTypography.titleMedium.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),


        onTap: () {
          Navigator.pop(context, category);
        },
      ),
    );
  }
}
