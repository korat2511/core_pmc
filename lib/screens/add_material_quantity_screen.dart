import 'dart:developer';

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddMaterialQuantityScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedMaterials;

  const AddMaterialQuantityScreen({
    super.key,
    required this.selectedMaterials,
  });

  @override
  State<AddMaterialQuantityScreen> createState() => _AddMaterialQuantityScreenState();
}

class _AddMaterialQuantityScreenState extends State<AddMaterialQuantityScreen> {
  List<Map<String, dynamic>> _materialsWithQuantities = [];
  List<TextEditingController> _quantityControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize materials with quantities
    _materialsWithQuantities = widget.selectedMaterials.map((material) => {
      ...material,
      'quantity': 0,
    }).toList();
    
    // Initialize controllers
    _quantityControllers = List.generate(
      _materialsWithQuantities.length,
      (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    for (final controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateQuantity(int index, String value) {
    setState(() {
      final quantity = int.tryParse(value) ?? 0;
      _materialsWithQuantities[index]['quantity'] = quantity;
    });
  }

  bool get _canContinue {
    return _materialsWithQuantities.any((material) => (material['quantity'] as int) > 0);
  }

  void _continueToTask() {
    // Filter out materials with zero quantity
    final materialsWithQuantities = _materialsWithQuantities
        .where((material) => (material['quantity'] as int) > 0)
        .toList();

    if (materialsWithQuantities.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Please add quantity for at least one material',
      );
      return;
    }

    // Return the materials with quantities
    Navigator.of(context).pop(materialsWithQuantities);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Add Material Used: Step 2/2',
          showBackButton: true,
          showDrawer: false,
        ),
        body: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Quantities',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enter quantities for the selected materials',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Materials List
            Expanded(
              child: ListView.builder(
                padding: ResponsiveUtils.responsivePadding(context),
                itemCount: _materialsWithQuantities.length,
                itemBuilder: (context, index) {

                  log("Material Stock = ${ _materialsWithQuantities[index]['current_stock']}");

                  final material = _materialsWithQuantities[index];
                  final currentStock = double.tryParse(material['current_stock']?.toString() ?? '0')?.toInt() ?? 0;
                  final unitOfMeasurement = material['unit_of_measurement'] ?? '';


                  log("Material Stock = $currentStock");

                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Material Name and Brand
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material['name'] ?? '',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${material['brand_name'] ?? ''}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ), SizedBox(height: 4),
                                  Text(
                                    'UOM: $unitOfMeasurement',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.successColor),
                              ),
                              child: Text(
                                'In Stock: $currentStock',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.successColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Quantity Input
                        Row(
                          children: [
                                                         Expanded(
                               child: CustomTextField(
                                 controller: _quantityControllers[index],
                                 label: 'Quantity Used',
                                 hintText: '0',
                                 keyboardType: TextInputType.number,
                                 onChanged: (value) => _updateQuantity(index, value),
                                 validator: (value) {
                                   final quantity = int.tryParse(value ?? '') ?? 0;
                                   if (quantity > currentStock) {
                                     return 'Quantity cannot exceed stock ($currentStock)';
                                   }
                                   return null;
                                 },
                               ),
                             ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.borderColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: Text(
                                unitOfMeasurement,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Stock Warning
                        if ((material['quantity'] as int) > 0 && (material['quantity'] as int) > currentStock) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.errorColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: AppColors.errorColor,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Quantity exceeds available stock',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.errorColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                border: Border(
                  top: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_materialsWithQuantities.where((m) => (m['quantity'] as int) > 0).length} with quantities',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  SizedBox(
                    width: 120,
                    child: CustomButton(
                      onPressed: _canContinue ? _continueToTask : null,
                      text: 'Continue',
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
