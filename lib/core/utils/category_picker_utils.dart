import 'package:flutter/material.dart';
import '../../models/site_model.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/category_picker_modal.dart';
import 'snackbar_utils.dart';

class CategoryPickerUtils {
  static Future<CategoryModel?> showCategoryPicker({
    required BuildContext context,
    required int siteId,
    List<int>? allowedSubIds, // Add validation for specific sub IDs
    List<int>? excludedCategoryIds, // Exclude already added categories
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Load categories
      final categoryService = CategoryService();
      final success = await categoryService.getCategoriesBySite(siteId: siteId);

      // Close loading dialog
      Navigator.pop(context);

      if (!success) {
        SnackBarUtils.showError(
          context,
          message: categoryService.errorMessage,
        );
        return null;
      }

      // Filter categories by allowed sub IDs if specified
      List<CategoryModel> filteredCategories = categoryService.categories;
      if (allowedSubIds != null && allowedSubIds.isNotEmpty) {
        filteredCategories = filteredCategories
            .where((category) => allowedSubIds.contains(category.catSubId))
            .toList();
      }

      // Filter out already added categories if specified
      if (excludedCategoryIds != null && excludedCategoryIds.isNotEmpty) {
        filteredCategories = filteredCategories
            .where((category) => !excludedCategoryIds.contains(category.id))
            .toList();
      }

      if (filteredCategories.isEmpty) {
        SnackBarUtils.showInfo(
          context,
          message: allowedSubIds != null && allowedSubIds.isNotEmpty || excludedCategoryIds != null && excludedCategoryIds.isNotEmpty
              ? 'No categories available for the specified criteria'
              : 'No categories available for this site',
        );
        return null;
      }

      // Show the modal and return selected category
      final selectedCategory = await showModalBottomSheet<CategoryModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => GestureDetector(
          onTap: () {
            // Close keyboard and modal when tapping outside
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: DraggableScrollableSheet(
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) => CategoryPickerModal(
                  categories: filteredCategories,
                ),
              ),
            ),
          ),
        ),
      );

      return selectedCategory;
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      SnackBarUtils.showError(
        context,
        message: 'Failed to load categories: $e',
      );
      return null;
    }
  }
}
