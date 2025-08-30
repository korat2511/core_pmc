import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../models/qc_category_model.dart';
import '../services/qc_category_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dismiss_keyboard.dart';
import 'qc_points_screen.dart';

class SiteQcCategoryScreen extends StatefulWidget {
  final SiteModel site;

  const SiteQcCategoryScreen({
    super.key,
    required this.site,
  });

  @override
  State<SiteQcCategoryScreen> createState() => _SiteQcCategoryScreenState();
}

class _SiteQcCategoryScreenState extends State<SiteQcCategoryScreen> {
  final QcCategoryService _qcCategoryService = QcCategoryService();
  List<QcCategoryModel> _filteredQcCategories = [];
  String _searchQuery = '';
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQcCategories();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _loadQcCategories() async {
    final success = await _qcCategoryService.getQcCategories();
    if (success) {
      setState(() {
        _filteredQcCategories = _qcCategoryService.qcCategories;
      });
    } else {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: _qcCategoryService.errorMessage,
        );
      }
    }
  }

  void _filterQcCategories(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredQcCategories = _qcCategoryService.qcCategories;
      } else {
        _filteredQcCategories = _qcCategoryService.qcCategories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddQcCategoryModal() {
    _categoryNameController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildAddQcCategoryModal(),
      ),
    );
  }



  Widget _buildAddQcCategoryModal() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Colors.green,
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
                        'Add QC Category',
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
                      Text(
                        widget.site.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                                          child: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  controller: _categoryNameController,
                  label: 'QC Category Name',
                  hintText: 'Enter QC category name',
                  prefixIcon: Icon(Icons.verified_outlined),
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
                    onPressed: _addQcCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                                              foregroundColor: Colors.white,
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
                    child: Text(
                      'Create QC Category',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        color: Colors.white,
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

  Future<void> _addQcCategory() async {
    final categoryName = _categoryNameController.text.trim();
    
    if (categoryName.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Please enter a QC category name',
      );
      return;
    }

    final success = await _qcCategoryService.createQcCategory(categoryName);
    
    if (success) {
      Navigator.of(context).pop();
      setState(() {
        _filteredQcCategories = _qcCategoryService.qcCategories;
      });
      SnackBarUtils.showSuccess(
        context,
        message: 'QC Category added successfully',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: _qcCategoryService.errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'QC Categories',
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
                hintText: 'Search QC categories...',
                onChanged: _filterQcCategories,
              ),
            ),

            // Category Count
            Padding(
              padding: ResponsiveUtils.horizontalPadding(context),
              child: Row(
                children: [
                  Text(
                    '${_filteredQcCategories.length} QC Categories',
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
                  const Spacer(),
                  GestureDetector(
                    onTap: _showAddQcCategoryModal,
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
                            'Add QC Category',
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

            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),

            // QC Categories List
            Expanded(
              child: _qcCategoryService.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : _filteredQcCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_outlined,
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
                                    ? 'No QC categories available'
                                    : 'No QC categories found',
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
                        )
                      : RefreshIndicator(
                          onRefresh: _loadQcCategories,
                          color: Theme.of(context).colorScheme.primary,
                          child: ListView.builder(
                            padding: ResponsiveUtils.horizontalPadding(context),
                            itemCount: _filteredQcCategories.length,
                            itemBuilder: (context, index) {
                              final qcCategory = _filteredQcCategories[index];
                              return _buildQcCategoryCard(qcCategory);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQcCategoryCard(QcCategoryModel qcCategory) {
    return GestureDetector(
      onTap: () {
        NavigationUtils.push(
          context,
          QcPointsScreen(
            site: widget.site,
            category: qcCategory,
          ),
        );
      },
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
      child: Padding(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Row(
          children: [
            // Icon
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
                color: Colors.green.withOpacity(0.1),
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
                Icons.verified_outlined,
                color: Colors.green,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 28,
                ),
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

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qcCategory.name,
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
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 4,
                      tablet: 6,
                      desktop: 8,
                    ),
                  ),
                  Text(
                    'ID: ${qcCategory.id}',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
