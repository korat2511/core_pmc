import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../core/utils/material_category_picker_utils.dart';
import '../models/material_category_model.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';

class AddMaterialScreen extends StatefulWidget {
  final SiteModel site;

  const AddMaterialScreen({
    super.key,
    required this.site,
  });

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  final _nameController = TextEditingController();
  final _specificationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _availableQuantityController = TextEditingController();
  final _minimumQuantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _hsnController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _breadthController = TextEditingController();
  final _diameterController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();

  // Selected values
  String? _selectedUOM;
  MaterialCategoryModel? _selectedCategory;
  String? _selectedGST;
  bool _isLoading = false;

  // Expandable sections
  bool _isStockDetailsExpanded = false;
  bool _isFinancialDetailsExpanded = false;
  bool _isAdditionalDetailsExpanded = false;

  // Popular UOM options
  final List<String> _uomOptions = [
    'Nos',
    'Kilograms (KG)',
    'Grams (G)',
    'Meters (M)',
    'Centimeters (CM)',
    'Millimeters (MM)',
    'Square Meters (SQM)',
    'Cubic Meters (CUM)',
    'Liters (L)',
    'Milliliters (ML)',
    'Boxes',
    'Bundles',
    'Rolls',
    'Sheets',
    'Bags',
    'Cans',
    'Bottles',
    'Units',
  ];

  // GST options
  final List<String> _gstOptions = [
    'GST0',
    'GST3',
    'GST5',
    'GST6',
    'GST12',
    'GST18',
    'GST28',
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    _nameController.dispose();
    _specificationController.dispose();
    _descriptionController.dispose();
    _itemCodeController.dispose();
    _availableQuantityController.dispose();
    _minimumQuantityController.dispose();
    _unitPriceController.dispose();
    _hsnController.dispose();
    _brandNameController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _diameterController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    super.dispose();
  }

    Future<void> _selectUOM() async {
    // Dismiss keyboard before opening modal
    FocusScope.of(context).unfocus();
    
    final selectedUOM = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Select UOM',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // UOM List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _uomOptions.length,
                        itemBuilder: (context, index) {
                          final uom = _uomOptions[index];
                          return ListTile(
                            title: Text(uom),
                            trailing: _selectedUOM == uom ? Icon(Icons.check, color: AppColors.primaryColor) : null,
                            onTap: () => Navigator.of(context).pop(uom),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (selectedUOM != null) {
      setState(() {
        _selectedUOM = selectedUOM;
      });
    }
    
    // Prevent keyboard from reopening
    await Future.delayed(Duration(milliseconds: 100));
    FocusScope.of(context).unfocus();
  }

  Future<void> _selectCategory() async {
    // Dismiss keyboard before opening modal
    FocusScope.of(context).unfocus();
    
    final category = await MaterialCategoryPickerUtils.showMaterialCategoryPicker(
      context: context,
    );
    
    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
    }
    
    // Prevent keyboard from reopening
    await Future.delayed(Duration(milliseconds: 100));
    FocusScope.of(context).unfocus();
  }

  Future<void> _selectGST() async {
    // Dismiss keyboard before opening modal
    FocusScope.of(context).unfocus();
    
    final selectedGST = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Select GST',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // GST List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _gstOptions.length,
                        itemBuilder: (context, index) {
                          final gst = _gstOptions[index];
                          return ListTile(
                            title: Text(gst),
                            trailing: _selectedGST == gst ? Icon(Icons.check, color: AppColors.primaryColor) : null,
                            onTap: () => Navigator.of(context).pop(gst),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (selectedGST != null) {
      setState(() {
        _selectedGST = selectedGST;
      });
    }
    
    // Prevent keyboard from reopening
    await Future.delayed(Duration(milliseconds: 100));
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUOM == null) {
      SnackBarUtils.showError(context, message: 'Please select UOM');
      return;
    }
    if (_selectedCategory == null) {
      SnackBarUtils.showError(context, message: 'Please select Category');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.saveMaterial(
        name: _nameController.text.trim(),
        unitOfMeasurement: _selectedUOM!,
        specification: _specificationController.text.trim(),
        categoryId: _selectedCategory!.id,
        sku: _itemCodeController.text.trim(),
        unitPrice: _unitPriceController.text.trim(),
        gst: _selectedGST,
        hsn: _hsnController.text.trim().isEmpty 
            ? null 
            : _hsnController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        brandName: _brandNameController.text.trim().isEmpty 
            ? null 
            : _brandNameController.text.trim(),
        minStock: _minimumQuantityController.text.trim().isEmpty 
            ? 0 
            : int.parse(_minimumQuantityController.text.trim()),
        availableStock: _availableQuantityController.text.trim().isEmpty 
            ? 0 
            : int.parse(_availableQuantityController.text.trim()),
        length: _lengthController.text.trim().isEmpty 
            ? null 
            : _lengthController.text.trim(),
        width: _breadthController.text.trim().isEmpty 
            ? null 
            : _breadthController.text.trim(),
        height: _heightController.text.trim().isEmpty 
            ? null 
            : _heightController.text.trim(),
        weight: _weightController.text.trim().isEmpty 
            ? null 
            : _weightController.text.trim(),
        color: _colorController.text.trim().isEmpty 
            ? null 
            : _colorController.text.trim(),
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message,
        );
        Navigator.of(context).pop();
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Failed to save material',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primaryColor,
            ),
            onTap: onToggle,
          ),
          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Add New Material',
          showDrawer: false,
          showBackButton: true,
        ),
        body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Material Name
              CustomTextField(
                controller: _nameController,
                label: 'Material Name *',
                hintText: 'Enter material name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter material name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Specification
              CustomTextField(
                controller: _specificationController,
                label: 'Specification *',
                hintText: 'Enter specification',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter specification';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hintText: 'Enter description (optional)',
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // UOM Selection
              GestureDetector(
                onTap: _selectUOM,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.straighten, color: AppColors.textSecondary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedUOM ?? 'Select UOM *',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _selectedUOM != null 
                                ? AppColors.textPrimary 
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Category Selection
              GestureDetector(
                onTap: _selectCategory,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category, color: AppColors.textSecondary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCategory?.name ?? 'Select Category *',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _selectedCategory != null 
                                ? AppColors.textPrimary 
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Item Code
              CustomTextField(
                controller: _itemCodeController,
                label: 'Item Code *',
                hintText: 'Enter item code',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item code';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Stock Details Section
              _buildExpandableSection(
                title: 'Stock Details',
                isExpanded: _isStockDetailsExpanded,
                onToggle: () {
                  setState(() {
                    _isStockDetailsExpanded = !_isStockDetailsExpanded;
                  });
                },
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _availableQuantityController,
                      label: 'Available Quantity',
                      hintText: 'Enter available quantity (optional)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _minimumQuantityController,
                      label: 'Minimum Quantity',
                      hintText: 'Enter minimum quantity (optional)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Financial Details Section
              _buildExpandableSection(
                title: 'Financial Details',
                isExpanded: _isFinancialDetailsExpanded,
                onToggle: () {
                  setState(() {
                    _isFinancialDetailsExpanded = !_isFinancialDetailsExpanded;
                  });
                },
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _unitPriceController,
                      label: 'Unit Price *',
                      hintText: 'Enter unit price',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter unit price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _hsnController,
                      label: 'HSN',
                      hintText: 'Enter HSN code (optional)',
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectGST,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.receipt, color: AppColors.textSecondary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedGST ?? 'Select GST',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: _selectedGST != null 
                                      ? AppColors.textPrimary 
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Additional Details Section
              _buildExpandableSection(
                title: 'Additional Details',
                isExpanded: _isAdditionalDetailsExpanded,
                onToggle: () {
                  setState(() {
                    _isAdditionalDetailsExpanded = !_isAdditionalDetailsExpanded;
                  });
                },
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _brandNameController,
                      label: 'Brand Name',
                      hintText: 'Enter brand name',
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _lengthController,
                            label: 'Length',
                            hintText: 'Length',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _breadthController,
                            label: 'Breadth',
                            hintText: 'Breadth',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _diameterController,
                            label: 'Diameter',
                            hintText: 'Diameter',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _heightController,
                            label: 'Height',
                            hintText: 'Height',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _weightController,
                            label: 'Weight',
                            hintText: 'Weight',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _colorController,
                            label: 'Color',
                            hintText: 'Color',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Save Material',
                  onPressed: _isLoading ? null : _saveMaterial,
                  isLoading: _isLoading,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
