import 'package:flutter/material.dart';
import '../../models/unit_model.dart';
import '../constants/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/responsive_utils.dart';
import '../utils/snackbar_utils.dart';
import '../../widgets/custom_search_bar.dart';

class UnitPickerUtils {
  static Future<UnitModel?> showUnitPicker(
    BuildContext context, {
    required List<UnitModel> units,
    UnitModel? selectedUnit,
  }) async {
    return await showModalBottomSheet<UnitModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Select Unit',
                            style: AppTypography.titleLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Search bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: CustomSearchBar(
                        hintText: 'Search units...',
                        onChanged: (value) {
                          // TODO: Implement search functionality
                        },
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Units list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: units.length,
                        itemBuilder: (context, index) {
                          final unit = units[index];
                          final isSelected = selectedUnit?.id == unit.id;
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop(unit);
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : AppColors.borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unit.name,
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Symbol: ${unit.symbol}',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
