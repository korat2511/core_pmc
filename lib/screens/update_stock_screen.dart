import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/material_stock_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

class UpdateStockScreen extends StatefulWidget {
  final MaterialDetailModel material;
  final String currentStock;
  final String siteName;

  const UpdateStockScreen({
    super.key,
    required this.material,
    required this.currentStock,
    required this.siteName,
  });

  @override
  State<UpdateStockScreen> createState() => _UpdateStockScreenState();
}

class _UpdateStockScreenState extends State<UpdateStockScreen> {
  bool _isUsedFromStock = true; // true = used from stock, false = add to stock
  final _quantityController = TextEditingController();
  final _commentsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _updateStock() async {
    if (_quantityController.text.isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter quantity');
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      SnackBarUtils.showError(context, message: 'Please enter a valid quantity');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.updateMaterialStock(
        materialId: widget.material.id,
        quantity: quantity,
        description: _commentsController.text.isEmpty 
            ? (_isUsedFromStock ? 'Manual used from stock out api' : 'Manual added from stock in api')
            : _commentsController.text,
        isStockIn: !_isUsedFromStock,
      );

      if (success) {
        SnackBarUtils.showSuccess(
          context,
          message: _isUsedFromStock 
              ? 'Stock used successfully' 
              : 'Stock added successfully',
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        SnackBarUtils.showError(context, message: 'Failed to update stock');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error updating stock: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: CustomAppBar(
        title: 'Update Stock',
        showBackButton: true,
        showDrawer: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inventory Context
            Text(
              'In: Project\'s inventory',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Divider
            Divider(color: AppColors.borderColor.withOpacity(0.3)),
            
            SizedBox(height: 12),
            
            // Item Details
            Text(
              widget.material.name,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'In Stock: ${widget.currentStock} ${widget.material.unitOfMeasurement}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Divider
            Divider(color: AppColors.borderColor.withOpacity(0.3)),
            
            SizedBox(height: 12),
            
            // Stock Action Selection
            Text(
              'Stock Action',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _isUsedFromStock,
                  onChanged: (value) {
                    setState(() {
                      _isUsedFromStock = value!;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
                Text(
                  'Used from stock',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  groupValue: _isUsedFromStock,
                  onChanged: (value) {
                    setState(() {
                      _isUsedFromStock = value!;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
                Text(
                  'Add to Stock',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Stock Quantity Input
            Text(
              'Quantity',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                // Minus/Plus Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isUsedFromStock 
                        ? Colors.red.withOpacity(0.08) 
                        : Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isUsedFromStock 
                          ? Colors.red.withOpacity(0.2) 
                          : Colors.green.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    _isUsedFromStock ? Icons.remove : Icons.add,
                    color: _isUsedFromStock ? Colors.red : Colors.green,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                
                // Quantity Input Field
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _isUsedFromStock 
                          ? 'Enter stock used' 
                          : 'Enter stock added',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryColor),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                
                // Unit Display
                Text(
                  widget.material.unitOfMeasurement,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Comments Section
            Text(
              'Comments',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            
            TextFormField(
              controller: _commentsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add comments here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            
            SizedBox(height: 28),
            
            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Update in stock',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
