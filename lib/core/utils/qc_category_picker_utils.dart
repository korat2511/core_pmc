import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/qc_category_model.dart';
import '../../services/qc_category_service.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/dismiss_keyboard.dart';

class QcCategoryPickerUtils {
  static Future<QcCategoryModel?> showQcCategoryPicker({
    required BuildContext context,
    QcCategoryModel? selectedCategory,
  }) async {
    return await showModalBottomSheet<QcCategoryModel?>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QcCategoryPickerModal(
        selectedCategory: selectedCategory,
      ),
    );
  }
}

class _QcCategoryPickerModal extends StatefulWidget {
  final QcCategoryModel? selectedCategory;

  const _QcCategoryPickerModal({
    this.selectedCategory,
  });

  @override
  State<_QcCategoryPickerModal> createState() => _QcCategoryPickerModalState();
}

class _QcCategoryPickerModalState extends State<_QcCategoryPickerModal> {
  final QcCategoryService _qcCategoryService = QcCategoryService();
  List<QcCategoryModel> _filteredQcCategories = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQcCategories();
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

  void _selectCategory(QcCategoryModel category) {
    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: DismissKeyboard(
            child: Column(
              children: [
                // Handle Bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: ResponsiveUtils.responsivePadding(context),
                  child: Row(
                    children: [
                      Text(
                        'Select QC Category',
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: ResponsiveUtils.horizontalPadding(context),
                  child: CustomSearchBar(
                    hintText: 'Search QC categories...',
                    onChanged: _filterQcCategories,
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
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: ResponsiveUtils.horizontalPadding(context),
                              itemCount: _filteredQcCategories.length,
                              itemBuilder: (context, index) {
                                final qcCategory = _filteredQcCategories[index];
                                return _buildQcCategoryItem(qcCategory);
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQcCategoryItem(QcCategoryModel qcCategory) {
    final isSelected = widget.selectedCategory?.id == qcCategory.id;

    return GestureDetector(
      onTap: () => _selectCategory(qcCategory),
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
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
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

              // Selection Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
