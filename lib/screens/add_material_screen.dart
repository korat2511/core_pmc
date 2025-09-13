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
import '../models/uom_model.dart';
import '../services/api_service.dart';
import '../services/uom_service.dart';

class AddMaterialScreen extends StatefulWidget {
  final SiteModel site;

  const AddMaterialScreen({super.key, required this.site});

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

  // UOM data from Firebase
  Map<String, List<UOMModel>> _uomCategories = {};
  bool _isLoadingUOMs = false;

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
  void initState() {
    super.initState();
    _loadUOMs();
  }

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

  Future<void> _loadUOMs() async {
    setState(() {
      _isLoadingUOMs = true;
    });

    try {
      // Load all UOMs
      final uoms = await UOMService.getAllUOMs();
      setState(() {
        _uomCategories = _organizeUOMsByCategory(uoms);
        _isLoadingUOMs = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUOMs = false;
      });
      SnackBarUtils.showError(context, message: 'Error loading units: $e');
    }
  }

  Map<String, List<UOMModel>> _organizeUOMsByCategory(List<UOMModel> uoms) {
    final Map<String, List<UOMModel>> categories = {};
    
    for (final uom in uoms) {
      if (!categories.containsKey(uom.category)) {
        categories[uom.category] = [];
      }
      categories[uom.category]!.add(uom);
    }
    
    // Sort categories: "Your Units" first, then others alphabetically
    final sortedCategories = <String, List<UOMModel>>{};
    
    // Add "Your Units" first if it exists
    if (categories.containsKey('Your Units')) {
      sortedCategories['Your Units'] = categories['Your Units']!;
    }
    
    // Add other categories alphabetically
    final otherCategories = categories.entries
        .where((entry) => entry.key != 'Your Units')
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    for (final entry in otherCategories) {
      sortedCategories[entry.key] = entry.value;
    }
    
    return sortedCategories;
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
      builder: (context) => _UOMSelectorModal(
        uomCategories: _uomCategories,
        selectedUOM: _selectedUOM,
        isLoading: _isLoadingUOMs,
        onUOMSelected: (uom) => Navigator.of(context).pop(uom),
        onUOMAdded: () async {
          // Reload UOMs after adding new one
          await _loadUOMs();
        },
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

    final category =
        await MaterialCategoryPickerUtils.showMaterialCategoryPicker(
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
          color: Colors.black.withValues(alpha: 0.5),
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
                            trailing: _selectedGST == gst
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.primaryColor,
                                  )
                                : null,
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
        SnackBarUtils.showSuccess(context, message: response.message);
        Navigator.of(context).pop();
      } else {
        SnackBarUtils.showError(context, message: 'Failed to save material');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error: ${e.toString()}');
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
            Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
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
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        ),
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
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        ),
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
                      _isFinancialDetailsExpanded =
                          !_isFinancialDetailsExpanded;
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt,
                                color: AppColors.textSecondary,
                              ),
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
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textSecondary,
                              ),
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
                      _isAdditionalDetailsExpanded =
                          !_isAdditionalDetailsExpanded;
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

class _UOMSelectorModal extends StatefulWidget {
  final Map<String, List<UOMModel>> uomCategories;
  final String? selectedUOM;
  final bool isLoading;
  final Function(String) onUOMSelected;
  final VoidCallback onUOMAdded;

  const _UOMSelectorModal({
    required this.uomCategories,
    required this.selectedUOM,
    required this.isLoading,
    required this.onUOMSelected,
    required this.onUOMAdded,
  });

  @override
  State<_UOMSelectorModal> createState() => _UOMSelectorModalState();
}

class _UOMSelectorModalState extends State<_UOMSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, List<UOMModel>> _localUomCategories = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localUomCategories = widget.uomCategories;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUOMs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uoms = await UOMService.getAllUOMs();
      setState(() {
        _localUomCategories = _organizeUOMsByCategory(uoms);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, List<UOMModel>> _organizeUOMsByCategory(List<UOMModel> uoms) {
    final Map<String, List<UOMModel>> categories = {};
    
    for (final uom in uoms) {
      if (!categories.containsKey(uom.category)) {
        categories[uom.category] = [];
      }
      categories[uom.category]!.add(uom);
    }
    
    // Sort categories: "Your Units" first, then others alphabetically
    final sortedCategories = <String, List<UOMModel>>{};
    
    // Add "Your Units" first if it exists
    if (categories.containsKey('Your Units')) {
      sortedCategories['Your Units'] = categories['Your Units']!;
    }
    
    // Add other categories alphabetically
    final otherCategories = categories.entries
        .where((entry) => entry.key != 'Your Units')
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    for (final entry in otherCategories) {
      sortedCategories[entry.key] = entry.value;
    }
    
    return sortedCategories;
  }

  List<UOMModel> get _filteredUOMs {
    if (_searchQuery.isEmpty) {
      return _localUomCategories.values.expand((uoms) => uoms).toList();
    }

    return _localUomCategories.values
        .expand((uoms) => uoms)
        .where(
          (uom) =>
              uom.abbreviation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              uom.fullName.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _addNewUOM() async {
    final abbreviationController = TextEditingController();
    final fullNameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: abbreviationController,
              decoration: InputDecoration(
                labelText: 'Abbreviation *',
                hintText: 'e.g., kg, m, sqft',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 16),
            TextField(
              controller: fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g., kilogram, meter, square feet',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final abbreviation = abbreviationController.text.trim();
              final fullName = fullNameController.text.trim();
              
              if (abbreviation.isNotEmpty && fullName.isNotEmpty) {
                Navigator.of(context).pop(true);
              } else {
                SnackBarUtils.showError(context, message: 'Please fill in both fields');
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final abbreviation = abbreviationController.text.trim();
      final fullName = fullNameController.text.trim();
      
      // Show loading
      SnackBarUtils.showInfo(context, message: 'Adding unit...');
      
      try {
        final success = await UOMService.addUOM(
          abbreviation: abbreviation,
          fullName: fullName,
          category: 'Your Units',
        );

        if (success) {
          SnackBarUtils.showSuccess(context, message: 'Unit added successfully');
          widget.onUOMAdded();
          // Refresh the modal data
          await _refreshUOMs();
        } else {
          SnackBarUtils.showError(context, message: 'Failed to add unit - may already exist');
        }
      } catch (e) {
        SnackBarUtils.showError(context, message: 'Error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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

                  // Header with title and action buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Select Unit',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: _addNewUOM,
                          icon: Icon(Icons.add, color: AppColors.primary),
                        ),
                        IconButton(
                          onPressed: () {
                            // Focus search field
                            FocusScope.of(context).requestFocus(FocusNode());
                          },
                          icon: Icon(Icons.search, color: AppColors.primary),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search units...',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 10),
                  // UOM List
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _searchQuery.isEmpty
                            ? _buildCategorizedList()
                            : _buildSearchResults(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorizedList() {
    return ListView.builder(
      itemCount: _localUomCategories.length,
      itemBuilder: (context, categoryIndex) {
        final categoryEntry = _localUomCategories.entries.elementAt(
          categoryIndex,
        );
        final categoryName = categoryEntry.key;
        final uoms = categoryEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Text(
                categoryName,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            // Category items
            ...uoms.asMap().entries.map((entry) {
              final index = entry.key;
              final uom = entry.value;
              final isLast = index == uoms.length - 1;
              return _buildUOMItem(uom.abbreviation, uom.fullName, isLast: isLast);
            }),
            SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final filteredUOMs = _filteredUOMs;

    if (filteredUOMs.isEmpty) {
      return Center(
        child: Text(
          'No units found',
          style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredUOMs.length,
      itemBuilder: (context, index) {
        final uom = filteredUOMs[index];
        final isLast = index == filteredUOMs.length - 1;
        return _buildUOMItem(uom.abbreviation, uom.fullName, isLast: isLast);
      },
    );
  }

  Widget _buildUOMItem(String abbreviation, String fullName, {bool isLast = false}) {
    return GestureDetector(
      onTap: () => widget.onUOMSelected(abbreviation),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  child: Text(
                    abbreviation,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  fullName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            if (!isLast) ...[
              SizedBox(height: 7),
              Divider(color: Colors.grey.withValues(alpha: 0.15)),
              SizedBox(height: 7),
            ],
          ],
        ),
      ),
    );
  }
}
