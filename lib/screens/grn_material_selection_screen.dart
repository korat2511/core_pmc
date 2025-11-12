import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../models/site_model.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import 'record_grn_screen.dart';

class GrnMaterialSelectionScreen extends StatefulWidget {
  final SiteModel site;

  const GrnMaterialSelectionScreen({super.key, required this.site});

  @override
  State<GrnMaterialSelectionScreen> createState() =>
      _GrnMaterialSelectionScreenState();
}

class _GrnMaterialSelectionScreenState
    extends State<GrnMaterialSelectionScreen> {
  List<MaterialModel> _materials = [];
  List<MaterialModel> _filteredMaterials = [];
  Map<int, TextEditingController> _quantityControllers = {};
  Map<int, bool> _selectedMaterials = {};
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all quantity controllers
    _quantityControllers.values.forEach((controller) => controller.dispose());
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
          _materials = response.data;
          _filteredMaterials = response.data;

          // Initialize quantity controllers and selection state
          for (var material in _materials) {
            _quantityControllers[material.id] = TextEditingController(
              text: '1',
            );
            _selectedMaterials[material.id] = false;
          }
        });
      } else {
        setState(() {
          _materials = [];
          _filteredMaterials = [];
        });
      }
    } catch (e) {
      setState(() {
        _materials = [];
        _filteredMaterials = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMaterials(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredMaterials = _materials;
        } else {
          _filteredMaterials = _materials.where((material) {
            return material.name.toLowerCase().contains(query.toLowerCase()) ||
                material.sku.toLowerCase().contains(query.toLowerCase()) ||
                material.brandName?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ==
                    true;
          }).toList();
        }
      });
    }
  }

  void _toggleMaterialSelection(int materialId) {
    setState(() {
      _selectedMaterials[materialId] = !_selectedMaterials[materialId]!;
    });
  }

  void _updateQuantity(int materialId, String value) {
    _quantityControllers[materialId]?.text = value;
  }

  List<Map<String, dynamic>> _getSelectedMaterials() {
    List<Map<String, dynamic>> selected = [];

    for (var entry in _selectedMaterials.entries) {
      if (entry.value) {
        final material = _materials.firstWhere((m) => m.id == entry.key);
        final quantity =
            int.tryParse(_quantityControllers[entry.key]?.text ?? '1') ?? 1;

        selected.add({
          'material_id': material.id,
          'material_name': material.name,
          'quantity': quantity,
          'unit_of_measurement': material.unitOfMeasurement,
          'sku': material.sku,
        });
      }
    }

    return selected;
  }

  void _proceedToRecordGrn() {
    // Close keyboard first
    FocusScope.of(context).unfocus();

    final selectedMaterials = _getSelectedMaterials();

    if (selectedMaterials.isEmpty) {
      SnackBarUtils.showWarning(
        context,
        message: 'Please select at least one material',
      );
      return;
    }

    // Navigate to Record GRN screen with selected materials
    NavigationUtils.push(
      context,
      RecordGrnScreen(site: widget.site, selectedMaterials: selectedMaterials),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Close keyboard when back button is pressed
        FocusScope.of(context).unfocus();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceColor,

        appBar: CustomAppBar(
          title: 'Select Materials for GRN',
          showDrawer: false,
          showBackButton: true,
        ),

        body: GestureDetector(
          onTap: () {
            // Close keyboard when tapping outside
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: ResponsiveUtils.responsivePadding(context),
                child: CustomSearchBar(
                  hintText: 'Search materials...',
                  onChanged: _filterMaterials,
                  controller: _searchController,
                ),
              ),

              // Selected Count
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(context).left,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_getSelectedMaterials().length} materials selected',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_getSelectedMaterials().isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedMaterials.updateAll((key, value) => false);
                          });
                        },
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Materials List
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add materials to your inventory first',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.horizontalPadding(
                            context,
                          ).left,
                          vertical: 8,
                        ),
                        itemCount: _filteredMaterials.length,
                        itemBuilder: (context, index) {
                          final material = _filteredMaterials[index];
                          final isSelected =
                              _selectedMaterials[material.id] ?? false;
                          final quantityController =
                              _quantityControllers[material.id];

                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: ResponsiveUtils.responsivePadding(
                                context,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Material Header
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (value) =>
                                            _toggleMaterialSelection(
                                              material.id,
                                            ),
                                        activeColor: AppColors.primaryColor,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              material.name,
                                              style: AppTypography.bodyLarge
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                            if (material.brandName != null) ...[
                                              SizedBox(height: 4),
                                              Text(
                                                'Brand: ${material.brandName}',
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                            SizedBox(height: 4),
                                            Text(
                                              'SKU: ${material.sku}',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 14,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 12),

                                  // Quantity Input
                                  Row(
                                    children: [
                                      Text(
                                        'Quantity:',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        width: 80,
                                        child: TextField(
                                          controller: quantityController,
                                          keyboardType: TextInputType.number,
                                          enabled: isSelected,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                          ),
                                          onChanged: (value) => _updateQuantity(
                                            material.id,
                                            value,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          material.unitOfMeasurement,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _proceedToRecordGrn,
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          icon: Icon(Icons.arrow_forward),
          label: Text('Next'),
        ),
      ),
    );
  }
}
