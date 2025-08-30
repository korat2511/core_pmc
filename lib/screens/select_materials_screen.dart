import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import 'add_material_quantity_screen.dart';

class SelectMaterialsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? preSelectedMaterials;

  const SelectMaterialsScreen({
    super.key,
    this.preSelectedMaterials,
  });

  @override
  State<SelectMaterialsScreen> createState() => _SelectMaterialsScreenState();
}

class _SelectMaterialsScreenState extends State<SelectMaterialsScreen> {
  List<Map<String, dynamic>> _availableMaterials = [];
  List<Map<String, dynamic>> _filteredMaterials = [];
  List<Map<String, dynamic>> _selectedMaterials = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    if (widget.preSelectedMaterials != null) {
      _selectedMaterials = List.from(widget.preSelectedMaterials!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getMaterials(page: 1);
      
      if (response != null && response.status == 1) {
        setState(() {
          _availableMaterials = response.data.map((material) => {
            'id': material.id,
            'name': material.name,
            'brand_name': material.brandName,
            'unit_of_measurement': material.unitOfMeasurement,
            'specification': material.specification,
            'sku': material.sku,
            'current_stock': material.currentStock ?? 0,
            'isSelected': _isMaterialPreSelected(material.id),
            'quantity': _getPreSelectedQuantity(material.id),
          }).toList();
          _filteredMaterials = List.from(_availableMaterials);
        });
      }
    } catch (e) {
      print('Error loading materials: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isMaterialPreSelected(int materialId) {
    if (widget.preSelectedMaterials == null) return false;
    return widget.preSelectedMaterials!.any((material) => material['id'] == materialId);
  }

  int _getPreSelectedQuantity(int materialId) {
    if (widget.preSelectedMaterials == null) return 0;
    final material = widget.preSelectedMaterials!.firstWhere(
      (material) => material['id'] == materialId,
      orElse: () => {'quantity': 0},
    );
    return material['quantity'] ?? 0;
  }

  void _filterMaterials(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMaterials = List.from(_availableMaterials);
      } else {
        _filteredMaterials = _availableMaterials.where((material) {
          return material['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                 material['brand_name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                 material['sku'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleMaterialSelection(int index) {
    setState(() {
      final material = _filteredMaterials[index];
      final isSelected = material['isSelected'] as bool;
      
      if (isSelected) {
        // Remove from selected
        material['isSelected'] = false;
        material['quantity'] = 0;
        _selectedMaterials.removeWhere((m) => m['id'] == material['id']);
      } else {
        // Add to selected
        material['isSelected'] = true;
        material['quantity'] = 1; // Default quantity
        _selectedMaterials.add({
          'id': material['id'],
          'name': material['name'],
          'brand_name': material['brand_name'],
          'unit_of_measurement': material['unit_of_measurement'],
          'quantity': 1,
        });
      }
    });
  }

  void _updateMaterialQuantity(int index, String value) {
    final quantity = int.tryParse(value) ?? 0;
    setState(() {
      _filteredMaterials[index]['quantity'] = quantity;
      
      // Update selected materials list
      final materialId = _filteredMaterials[index]['id'];
      final selectedIndex = _selectedMaterials.indexWhere((m) => m['id'] == materialId);
      if (selectedIndex != -1) {
        _selectedMaterials[selectedIndex]['quantity'] = quantity;
      }
    });
  }

  void _continueToQuantityScreen() {
    // Filter selected materials
    final selectedMaterials = _availableMaterials
        .where((material) => material['isSelected'] as bool)
        .map((material) => {
              'id': material['id'],
              'name': material['name'],
              'brand_name': material['brand_name'],
              'unit_of_measurement': material['unit_of_measurement'],
              'current_stock': material['current_stock'],
            })
        .toList();

    if (selectedMaterials.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Please select at least one material',
      );
      return;
    }

    // Navigate to quantity screen
    NavigationUtils.push(
      context,
      AddMaterialQuantityScreen(
        selectedMaterials: selectedMaterials,
      ),
    ).then((result) {
      if (result != null) {
        // Return the materials with quantities to the previous screen
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Material Used: Step 1/2',
        showBackButton: true,
        showDrawer: false,
      ),
      body: Column(
        children: [
          // Inventory Selector
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Inventory:',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Project',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CustomSearchBar(
              hintText: 'Search',
              onChanged: _filterMaterials,
              controller: _searchController,
            ),
          ),

          SizedBox(height: 16),

          // Filter and Sort Options
          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Sort By'),
                SizedBox(width: 8),
                _buildFilterChip('Tags'),
                SizedBox(width: 8),
                _buildFilterChip('Item Code'),
                SizedBox(width: 8),
                _buildFilterChip('Brand'),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Materials List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  )
                : _filteredMaterials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No materials found',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMaterials.length,
                        itemBuilder: (context, index) {
                          final material = _filteredMaterials[index];
                          final isSelected = material['isSelected'] as bool;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) => _toggleMaterialSelection(index),
                                activeColor: AppColors.primaryColor,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material['name'] ?? '',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    material['specification'] ?? '',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Brand: ${material['brand_name'] ?? ''} | UOM: ${material['unit_of_measurement'] ?? ''}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'In Stock: ${material['current_stock']} ${material['unit_of_measurement'] ?? ''}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.successColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.borderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedMaterials.length} selected',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedMaterials.isNotEmpty ? _continueToQuantityScreen : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
