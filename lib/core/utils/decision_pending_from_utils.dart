import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/responsive_utils.dart';
import '../utils/snackbar_utils.dart';

class DecisionPendingFromUtils {
  /// Show a modal bottom sheet for selecting decision pending from agency
  /// Returns a Map with 'agency' and 'other' keys, or null if cancelled
  static Future<Map<String, String>?> showDecisionPendingFromPicker({
    required BuildContext context,
    required int catSubId,
    String? initialAgency,
    String? initialOther,
  }) async {
    // Convert single selection to multiple selection format
    List<String> selectedAgencies = [];
    if (initialAgency != null && initialAgency.isNotEmpty) {
      selectedAgencies = initialAgency.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    String? otherText = initialOther;

    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Header
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                'Select ${_getCategoryName(catSubId)} Pending From',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Agency options
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _getAgencyOptions(catSubId).length,
                            itemBuilder: (context, index) {
                              final agency = _getAgencyOptions(catSubId)[index];
                              final isSelected = selectedAgencies.contains(agency);

                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedAgencies.remove(agency);
                                    } else {
                                      selectedAgencies.add(agency);
                                    }
                                    // Clear other text if "Other" is not selected
                                    if (!selectedAgencies.contains('Other')) {
                                      otherText = null;
                                    }
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryColor.withOpacity(0.1)
                                        : AppColors.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : AppColors.borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          agency,
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Other text field (only show if "Other" is selected)
                        if (selectedAgencies.contains('Other')) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Specify Other *',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  onChanged: (value) {
                                    setModalState(() {
                                      otherText = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Enter other agency name',
                                    hintText: 'Enter other agency name...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.errorColor,
                                      ),
                                    ),
                                    suffixIcon: otherText != null &&
                                            otherText!.trim().isNotEmpty
                                        ? Icon(
                                            Icons.check_circle,
                                            color: AppColors.successColor,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'This field is required when "Other" is selected',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        // Action buttons
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Validate selection
                                    if (selectedAgencies.isEmpty) {
                                      SnackBarUtils.showError(
                                        context,
                                        message: 'Please select at least one agency',
                                      );
                                      return;
                                    }

                                    if (selectedAgencies.contains('Other')) {
                                      if (otherText == null || otherText!.trim().isEmpty) {
                                        SnackBarUtils.showError(
                                          context,
                                          message: 'Please specify the other agency name',
                                        );
                                        return;
                                      }
                                      if (otherText!.trim().length < 4) {
                                        SnackBarUtils.showError(
                                          context,
                                          message: 'Please enter at least 4 characters for the agency name',
                                        );
                                        return;
                                      }
                                    }

                                    // Return the result
                                    Navigator.pop(context, {
                                      'agency': selectedAgencies.join(','),
                                      'other': selectedAgencies.contains('Other') ? otherText!.trim() : '',
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: AppColors.textWhite,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    selectedAgencies.isEmpty ? 'Select' : 'Select (${selectedAgencies.length})',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    return result;
  }

  /// Get agency options based on cat_sub_id
  static List<String> _getAgencyOptions(int catSubId) {
    switch (catSubId) {
      case 2: // Decision
        return ["PMC", "Client", "Architect", "Vendor", "Structure", "Other"];
      case 3: // Drawing
        return ["Architect", "Structure", "Other"];
      case 4: // Selection
        return ["Architect", "Client"];
      case 6: // Quotation
        return ["Architect", "Structure", "Other"];
      default:
        return [];
    }
  }

  /// Get category name based on cat_sub_id
  static String _getCategoryName(int catSubId) {
    switch (catSubId) {
      case 2:
        return 'Decision';
      case 3:
        return 'Drawing';
      case 4:
        return 'Selection';
      case 6:
        return 'Quotation';
      default:
        return 'Category';
    }
  }
}
