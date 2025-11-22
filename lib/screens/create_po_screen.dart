import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/material_model.dart';
import '../models/billing_address_model.dart';

import '../models/site_vendor_model.dart';
import '../models/terms_and_condition_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../core/utils/state_picker_utils.dart';
import '../core/utils/payment_terms_picker_utils.dart';
import '../services/auth_service.dart';
import 'add_material_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class CreatePOScreen extends StatefulWidget {
  final SiteModel site;

  const CreatePOScreen({super.key, required this.site});

  @override
  State<CreatePOScreen> createState() => _CreatePOScreenState();
}

class _CreatePOScreenState extends State<CreatePOScreen> {
  int _currentStep = 0;
  final int _numSteps = 3;

  // Step 1: Material Selection
  List<MaterialModel> _materials = [];
  List<MaterialModel> _filteredMaterials = [];
  Set<int> _selectedMaterialIds = {};
  bool _isLoadingMaterials = false;
  final _materialSearchController = TextEditingController();

  // Step 2: Quantities & Rates
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _unitPriceControllers = {};
  final Map<int, TextEditingController> _discountControllers = {};
  final Map<int, TextEditingController> _taxControllers = {};

  // Step 3: Delivery & Terms
  final _purchaseOrderIdController = TextEditingController();
  bool _isCustomOrderId = false;
  bool _isLoadingOrderId = false;
  SiteVendorModel? _selectedVendor;
  DateTime? _expectedDeliveryDate;
  BillingAddressModel? _selectedDeliveryAddress;
  BillingAddressModel? _selectedBillingAddress;
  TermsAndConditionModel? _selectedTermsAndCondition;
  String? _selectedPaymentTerms;
  final _remarksController = TextEditingController();

  // Data for pickers
  List<SiteVendorModel> _vendors = [];
  List<BillingAddressModel> _billingAddresses = [];
  List<TermsAndConditionModel> _termsAndConditions = [];
  bool _isLoadingVendors = false;
  bool _isLoadingAddresses = false;
  bool _isLoadingTerms = false;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _generateAutoOrderId();
  }

  @override
  void dispose() {
    _materialSearchController.dispose();
    _purchaseOrderIdController.dispose();
    _remarksController.dispose();

    // Dispose all dynamic controllers
    _quantityControllers.values.forEach((controller) => controller.dispose());
    _unitPriceControllers.values.forEach((controller) => controller.dispose());
    _discountControllers.values.forEach((controller) => controller.dispose());
    _taxControllers.values.forEach((controller) => controller.dispose());

    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoadingMaterials = true;
    });

    try {
      final response = await ApiService.getMaterials(
        siteId: widget.site.id,
        page: 1,
        search: _materialSearchController.text.trim().isEmpty ? null : _materialSearchController.text.trim(),
      );

      if (response != null && response.status == 1) {
        setState(() {
          _materials = response.data;
          _filteredMaterials = response.data;
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
        _isLoadingMaterials = false;
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
      if (_selectedMaterialIds.contains(materialId)) {
        _selectedMaterialIds.remove(materialId);
        // Remove controllers for deselected material
        _quantityControllers[materialId]?.dispose();
        _unitPriceControllers[materialId]?.dispose();
        _discountControllers[materialId]?.dispose();
        _taxControllers[materialId]?.dispose();
        _quantityControllers.remove(materialId);
        _unitPriceControllers.remove(materialId);
        _discountControllers.remove(materialId);
        _taxControllers.remove(materialId);
      } else {
        _selectedMaterialIds.add(materialId);
        // Create controllers for selected material
        final material = _materials.firstWhere((m) => m.id == materialId);
        _quantityControllers[materialId] = TextEditingController();
        _unitPriceControllers[materialId] = TextEditingController(
          text: material.unitPrice,
        );
        _discountControllers[materialId] = TextEditingController();
        _taxControllers[materialId] = TextEditingController();

        // Add listeners for real-time calculations
        _quantityControllers[materialId]!.addListener(() => setState(() {}));
        _unitPriceControllers[materialId]!.addListener(() => setState(() {}));
        _discountControllers[materialId]!.addListener(() => setState(() {}));
        _taxControllers[materialId]!.addListener(() => setState(() {}));
      }
    });
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedMaterialIds.isNotEmpty;
      case 1:
        // Check if all selected materials have valid quantities
        for (final materialId in _selectedMaterialIds) {
          final quantity = _quantityControllers[materialId]?.text.trim();
          if (quantity == null ||
              quantity.isEmpty ||
              double.tryParse(quantity) == null) {
            return false;
          }
        }
        return true;
      case 2:
        return true; // Delivery & Terms is optional
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceedToNextStep() && _currentStep < _numSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        // Clear data for the step we're going back to
        if (_currentStep == 2) {
          // Going back from Step 3 to Step 2, clear Step 2 data
          _clearStep2Data();
        } else if (_currentStep == 1) {
          // Going back from Step 2 to Step 1, clear Step 1 data
          _clearStep1Data();
        }
        _currentStep--;
      });
    }
  }

  // Clear Step 1 data (Quantities & Rates)
  void _clearStep1Data() {
    // Clear all quantity, unit price, discount, and tax controllers
    for (final materialId in _selectedMaterialIds) {
      _quantityControllers[materialId]?.clear();
    
      _discountControllers[materialId]?.clear();
      _taxControllers[materialId]?.clear();
    }
  }

  // Clear Step 2 data (Delivery & Terms)
  void _clearStep2Data() {
    _purchaseOrderIdController.clear();
    _isCustomOrderId = false;
    _selectedVendor = null;
    _expectedDeliveryDate = null;
    _selectedDeliveryAddress = null;
    _selectedBillingAddress = null;
    _selectedTermsAndCondition = null;
    _selectedPaymentTerms = null;
    _remarksController.clear();
    // Regenerate auto order ID
    _generateAutoOrderId();
  }

  // Clear all data (when back button is clicked)
  void _clearAllData() {
    // Clear Step 1 data
    _clearStep1Data();
    
    // Clear Step 2 data
    _clearStep2Data();
    
    // Clear Step 0 data (material selection)
    _selectedMaterialIds.clear();
    _materialSearchController.clear();
    _filteredMaterials = List.from(_materials);
    
    // Reset to first step
    _currentStep = 0;
  }

  double _calculateTotalPrice(int materialId) {
    final quantity =
        double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '') ??
        0;
    final unitPrice =
        double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '') ??
        0;
    final discount =
        double.tryParse(_discountControllers[materialId]?.text.trim() ?? '') ??
        0;
    final tax =
        double.tryParse(_taxControllers[materialId]?.text.trim() ?? '') ?? 0;

    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    final taxableValue = subtotal - discountAmount;
    final taxAmount = taxableValue * (tax / 100);
    final total = taxableValue + taxAmount;

    return total;
  }

  double _calculateTotalTaxableValue(int materialId) {
    final quantity =
        double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '') ??
        0;
    final unitPrice =
        double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '') ??
        0;
    final discount =
        double.tryParse(_discountControllers[materialId]?.text.trim() ?? '') ??
        0;

    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    return subtotal - discountAmount;
  }

  double _calculateTaxAmount(int materialId) {
    final taxableValue = _calculateTotalTaxableValue(materialId);
    final tax =
        double.tryParse(_taxControllers[materialId]?.text.trim() ?? '') ?? 0;
    return taxableValue * (tax / 100);
  }

  double _calculateDiscountAmount(int materialId) {
    final quantity =
        double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '') ??
        0;
    final unitPrice =
        double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '') ??
        0;
    final discount =
        double.tryParse(_discountControllers[materialId]?.text.trim() ?? '') ??
        0;

    final subtotal = quantity * unitPrice;
    return subtotal * (discount / 100);
  }

  double _calculateTotalOrderAmount() {
    double total = 0;
    for (final materialId in _selectedMaterialIds) {
      total += _calculateTotalPrice(materialId);
    }
    return total;
  }


  // Helper method to format currency with Indian numbering system (commas every 2 digits from right)
  // Example: 290000 -> 2,90,000.00
  // Returns only the number part (without ₹) since ₹ is added in display strings
  String _formatCurrency(double amount) {
    if (amount == 0) {
      return '0.00';
    }

    final isNegative = amount < 0;
    final absAmount = amount.abs();

    // Split into integer and decimal parts
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Format integer part with Indian numbering system
    // Pattern: first 3 digits from right, then groups of 2 digits
    // Example: 290000 -> 2,90,000
    String formattedInteger = '';
    final reversed = integerPart.split('').reversed.toList();
    
    for (int i = 0; i < reversed.length; i++) {
      // Add comma before digit if needed
      if (i == 3) {
        // After first 3 digits, add comma before this digit
        formattedInteger = ',' + formattedInteger;
      } else if (i > 3 && (i - 3) % 2 == 0) {
     
        formattedInteger = ',' + formattedInteger;
      }
    
      formattedInteger = reversed[i] + formattedInteger;
    }

    final prefix = isNegative ? '-' : '';
    return '$prefix$formattedInteger.$decimalPart';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _clearAllData();
        return true; // Allow navigation back
      },
      child: Scaffold(
      appBar: CustomAppBar(
        title: 'Create Purchase Order',
        showDrawer: false,
        showBackButton: true,
          onBackPressed: () {
            _clearAllData();
            Navigator.of(context).pop();
          },
      ),
      body: Column(
        children: [
          // Stepper Header
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: List.generate(_numSteps, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      // Step Circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primaryColor
                              : isActive
                              ? AppColors.primaryColor
                              : AppColors.borderColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      // Step Title
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _getStepTitle(index),
                            style: AppTypography.bodySmall.copyWith(
                              color: isActive
                                  ? AppColors.primaryColor
                                  : AppColors.textSecondary,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Connector Line
                      if (index < _numSteps - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? AppColors.primaryColor
                                : AppColors.borderColor,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Step Content
          Expanded(child: _buildStepContent()),

          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: CustomButton(
                      text: 'Previous',
                      onPressed: _previousStep,
                      backgroundColor: Colors.grey[300]!,
                      textColor: AppColors.textPrimary,
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: _currentStep == _numSteps - 1 ? 'Create PO' : 'Next',
                    onPressed: _canProceedToNextStep()
                        ? (_currentStep == _numSteps - 1
                              ? _createPO
                              : _nextStep)
                        : null,
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

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select Material';
      case 1:
        return 'Quantities & Rates';
      case 2:
        return 'Delivery & Terms';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildMaterialSelectionStep();
      case 1:
        return _buildQuantitiesRatesStep();
      case 2:
        return _buildDeliveryTermsStep();
      default:
        return Container();
    }
  }

  Widget _buildMaterialSelectionStep() {
    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Column(
        children: [
          SizedBox(height: 8),
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: CustomSearchBar(
              hintText: 'Search materials...',
              onChanged: _filterMaterials,
              controller: _materialSearchController,
            ),
          ),
          SizedBox(height: 12),
          // Add Material Button
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Add Material',
                onPressed: () async {
                  // Navigate to create material screen using NavigationUtils
                  final result = await NavigationUtils.push(
                    context,
                    AddMaterialScreen(site: widget.site,),
                  );
                  // Reload materials when returning from create material screen
                  if (result != null) {
                    _loadMaterials();
                  }
                },
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: _isLoadingMaterials
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
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first material to get started',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: ResponsiveUtils.responsivePadding(context),
                    itemCount: _filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _filteredMaterials[index];
                      final isSelected = _selectedMaterialIds.contains(
                        material.id,
                      );

                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (value) =>
                                _toggleMaterialSelection(material.id),
                            activeColor: AppColors.primaryColor,
                          ),
                          title: Text(
                            material.name,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SKU: ${material.sku}'),
                              Text('${material.specification}'),
                              Text('In Stock: ${material.currentStock}'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitiesRatesStep() {
    if (_selectedMaterialIds.isEmpty) {
      return Center(
        child: Text(
          'No materials selected',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: ListView.builder(
        padding: ResponsiveUtils.responsivePadding(context),
        itemCount: _selectedMaterialIds.length,
        itemBuilder: (context, index) {
          final materialId = _selectedMaterialIds.elementAt(index);
          final material = _materials.firstWhere((m) => m.id == materialId);

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Material Header
                  Text(
                    material.name,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'SKU: ${material.sku} | UOM: ${material.unitOfMeasurement}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Input Fields
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label:
                              'Ordered Quantity (${material.unitOfMeasurement})',
                          controller: _quantityControllers[materialId]!,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Unit Price (₹)',
                          controller: _unitPriceControllers[materialId]!,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Discount (%)',
                          controller: _discountControllers[materialId]!,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Tax (%)',
                          controller: _taxControllers[materialId]!,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Calculations
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildCalculationRow(
                          'Subtotal',
                          '₹${_formatCurrency((double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '0') ?? 0) * (double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '0') ?? 0))}',
                        ),
                        _buildCalculationRow(
                          'Discount',
                          '-₹${_formatCurrency(_calculateDiscountAmount(materialId))}',
                        ),
                        _buildCalculationRow(
                          'Taxable Value',
                          '₹${_formatCurrency(_calculateTotalTaxableValue(materialId))}',
                        ),
                                                 _buildCalculationRow(
                           'CGST (${(double.tryParse(_taxControllers[materialId]?.text.trim() ?? '0') ?? 0) / 2}%)',
                           '₹${_formatCurrency(_calculateTaxAmount(materialId) / 2)}',
                         ),
                         _buildCalculationRow(
                           'SGST (${(double.tryParse(_taxControllers[materialId]?.text.trim() ?? '0') ?? 0) / 2}%)',
                           '₹${_formatCurrency(_calculateTaxAmount(materialId) / 2)}',
                         ),
                        Divider(),
                        _buildCalculationRow(
                          'Total Price',
                          '₹${_formatCurrency(_calculateTotalPrice(materialId))}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primaryColor : AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primaryColor : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTermsStep() {
    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purchase Order ID
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Purchase Order ID*',
                        controller: _purchaseOrderIdController,
                        hintText: _isLoadingOrderId
                            ? 'Generating...'
                            : 'Enter purchase order ID',
                        readOnly: !_isCustomOrderId && !_isLoadingOrderId,
                      ),
                    ),
                    if (!_isCustomOrderId && !_isLoadingOrderId) ...[
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _showCustomOrderIdDialog,
                        icon: Icon(Icons.edit, color: AppColors.primaryColor),
                        tooltip: 'Use Custom ID',
                      ),
                    ],
                    if (_isCustomOrderId) ...[
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _regenerateOrderId,
                        icon: Icon(
                          Icons.refresh,
                          color: AppColors.primaryColor,
                        ),
                        tooltip: 'Regenerate Auto ID',
                      ),
                    ],
                  ],
                ),
                if (!_isCustomOrderId && !_isLoadingOrderId)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Auto-generated ID. Tap edit icon to use custom ID.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_isCustomOrderId)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Custom ID mode. Tap refresh icon to use auto-generated ID.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_isLoadingOrderId)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Generating order ID...',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Vendor Name
            GestureDetector(
              onTap: () => _showVendorPicker(),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vendor Name',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedVendor?.name ?? 'Select vendor',
                            style: AppTypography.bodyLarge.copyWith(
                              color: _selectedVendor != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Expected Delivery Date
            GestureDetector(
              onTap: () => _showDeliveryDatePicker(),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expected Delivery Date',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _expectedDeliveryDate != null
                                ? '${_expectedDeliveryDate!.day}/${_expectedDeliveryDate!.month}/${_expectedDeliveryDate!.year}'
                                : 'Select delivery date',
                            style: AppTypography.bodyLarge.copyWith(
                              color: _expectedDeliveryDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Delivery Address
            GestureDetector(
              onTap: () => _showDeliveryAddressPicker(),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedDeliveryAddress?.address ??
                                'Select delivery address',
                            style: AppTypography.bodyLarge.copyWith(
                              color: _selectedDeliveryAddress != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Billing Address
            GestureDetector(
              onTap: () => _showBillingAddressPicker(),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Billing Address',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedBillingAddress?.address ??
                                'Select billing address',
                            style: AppTypography.bodyLarge.copyWith(
                              color: _selectedBillingAddress != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Terms and Condition
            GestureDetector(
              onTap: () => _showTermsAndConditionPicker(),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms and Condition',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedTermsAndCondition?.termAndCondition ??
                                'Select terms and condition',
                            style: AppTypography.bodyLarge.copyWith(
                              color: _selectedTermsAndCondition != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Payment Terms
            GestureDetector(
              onTap: () => _showPaymentTermsPicker(),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Terms',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedPaymentTerms ?? 'Select payment terms',
                            style: AppTypography.bodyLarge.copyWith(
                              color: _selectedPaymentTerms != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Remarks
            CustomTextField(
              label: 'Remarks',
              controller: _remarksController,
              maxLines: 3,
              hintText: 'Additional notes or special instructions',
            ),
            SizedBox(height: 24),

            // Order Summary
            if (_selectedMaterialIds.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildCalculationRow('Total Items', '${_selectedMaterialIds.length}'),
                    _buildCalculationRow('Total Amount', '₹${_formatCurrency(_calculateTotalOrderAmount())}'),
                    Divider(height: 16),
                    Text(
                      'Ready to create purchase order',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _createPO() async {
    // Validate required fields
    if (_purchaseOrderIdController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, message: 'Purchase Order ID is required');
      return;
    }

    if (_selectedVendor == null) {
      SnackBarUtils.showError(context, message: 'Please select a vendor');
      return;
    }

    if (_expectedDeliveryDate == null) {
      SnackBarUtils.showError(context, message: 'Please select delivery date');
      return;
    }

    if (_selectedDeliveryAddress == null) {
      SnackBarUtils.showError(context, message: 'Please select delivery address');
      return;
    }

    if (_selectedBillingAddress == null) {
      SnackBarUtils.showError(context, message: 'Please select billing address');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        Navigator.of(context).pop(); // Close loading dialog
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      // Prepare materials data
      List<Map<String, dynamic>> materialsData = [];
      for (final materialId in _selectedMaterialIds) {
        final material = _materials.firstWhere((m) => m.id == materialId);
        final quantity = _quantityControllers[materialId]?.text.trim() ?? '0';
        final unitPrice = _unitPriceControllers[materialId]?.text.trim() ?? '0';
        final discount = _discountControllers[materialId]?.text.trim() ?? '0';
        final tax = _taxControllers[materialId]?.text.trim() ?? '0';

        // Validate required fields
        if (quantity.isEmpty || unitPrice.isEmpty) {
          Navigator.of(context).pop(); // Close loading dialog
          SnackBarUtils.showError(
            context,
            message: 'Please fill all required fields for material: ${material.name}',
          );
          return;
        }

        // Calculate CGST and SGST (divide tax by 2)
        final taxValue = double.tryParse(tax.isEmpty ? '0' : tax) ?? 0;
        final cgst = (taxValue / 2).toString();
        final sgst = (taxValue / 2).toString();
        final igst = '0'; // IGST is 0 for same state

        materialsData.add({
          'material_id': materialId.toString(),
          'unit_price': unitPrice,
          'discount_value': discount.isEmpty ? '0' : discount, // Ensure it's a number, not empty string
          'discount_type': 'percentage',
          'quantity_for_delivery': quantity,
          'sgst': sgst,
          'cgst': cgst,
          'igst': igst,
        });
      }

      // Validate materials data
      if (materialsData.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        SnackBarUtils.showError(
          context,
          message: 'Please select at least one material',
        );
        return;
      }

      // Calculate total CGST and SGST for the order
      double totalTax = 0;
      for (final materialId in _selectedMaterialIds) {
        final taxText = _taxControllers[materialId]?.text.trim() ?? '0';
        final tax = double.tryParse(taxText.isEmpty ? '0' : taxText) ?? 0;
        totalTax += tax;
      }
      
      final totalCgst = (totalTax / 2).toString();
      final totalSgst = (totalTax / 2).toString();
      final totalIgst = '0';

      // Debug: Print request data
      print('Creating PO with data:');
      print('Site ID: ${widget.site.id}');
      print('PO ID: ${_purchaseOrderIdController.text.trim()}');
      print('Vendor ID: ${_selectedVendor!.id}');
      print('Delivery Date: ${_expectedDeliveryDate!.year}-${_expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${_expectedDeliveryDate!.day.toString().padLeft(2, '0')}');
      print('Billing Address ID: ${_selectedBillingAddress!.id}');
      print('Delivery Address: ${_selectedDeliveryAddress!.address}');
      print('Materials: ${materialsData.length} items');
      print('Total CGST: $totalCgst, SGST: $totalSgst, IGST: $totalIgst');

      // Call API
      final response = await ApiService.createPurchaseOrder(
        apiToken: token,
        siteId: widget.site.id.toString(),
        purchaseOrderId: _purchaseOrderIdController.text.trim(),
        vendorId: _selectedVendor!.id.toString(),
        expectedDeliveryDate: '${_expectedDeliveryDate!.year}-${_expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${_expectedDeliveryDate!.day.toString().padLeft(2, '0')}',
        billingAddressId: _selectedBillingAddress!.id.toString(),
        deliveryAddress: _selectedDeliveryAddress!.address,
        deliveryState: _selectedDeliveryAddress!.state,
        deliveryContactName: _selectedDeliveryAddress!.companyName,
        deliveryContactNo: '9737018701', // You might want to add this field to the address model
        materials: materialsData,
        cgst: totalCgst,
        sgst: totalSgst,
        igst: totalIgst,
      );

      Navigator.of(context).pop(); // Close loading dialog

      // Debug: Print response
      print('API Response:');
      print('Status: ${response.status}');
      print('Message: ${response.message}');
      print('Data: ${response.data}');

      if (response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message.isNotEmpty ? response.message : "Purchase Order created successfully!",
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message.isNotEmpty ? response.message : "Failed to create purchase order",
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      SnackBarUtils.showError(
        context,
        message: "Error creating purchase order: $e",
      );
    }
  }

  // Generate auto order ID
  Future<void> _generateAutoOrderId() async {
    setState(() {
      _isLoadingOrderId = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.generateOrderId(
          apiToken: token,
          type: 'po',
          siteId: widget.site.id,
        );

        if (response.status == 1 && response.data != null) {
          final orderId = response.data!['order_id'] as String?;
          if (orderId != null) {
            setState(() {
              _purchaseOrderIdController.text = orderId;
              _isCustomOrderId = false;
            });
          }
        } else {
          print('Failed to generate order ID: ${response.message}');
        }
      }
    } catch (e) {
      print('Error generating order ID: $e');
    } finally {
      setState(() {
        _isLoadingOrderId = false;
      });
    }
  }

  // Show custom order ID dialog
  void _showCustomOrderIdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom Purchase Order ID'),
        content: Text(
          'Do you want to use a custom purchase order ID instead of the auto-generated one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isCustomOrderId = true;
                _purchaseOrderIdController.clear();
              });
            },
            child: Text('Yes, Use Custom ID'),
          ),
        ],
      ),
    );
  }

  // Regenerate order ID
  void _regenerateOrderId() {
    setState(() {
      _isCustomOrderId = false;
    });
    _generateAutoOrderId();
  }

  // Picker Methods
  void _showVendorPicker() async {
    if (_vendors.isEmpty) {
      await _loadVendors();
    }

    final selectedVendor = await showModalBottomSheet<SiteVendorModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVendorPickerBottomSheet(),
    );

    if (selectedVendor != null) {
      setState(() {
        _selectedVendor = selectedVendor;
      });
    }
  }

  void _showDeliveryDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _expectedDeliveryDate = date;
      });
    }
  }

  void _showDeliveryAddressPicker() async {
    if (_billingAddresses.isEmpty) {
      await _loadBillingAddresses();
    }

    final selectedAddress = await showModalBottomSheet<BillingAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddressPickerBottomSheet('Delivery'),
    );

    if (selectedAddress != null) {
      setState(() {
        _selectedDeliveryAddress = selectedAddress;
      });
    }
  }

  void _showBillingAddressPicker() async {
    if (_billingAddresses.isEmpty) {
      await _loadBillingAddresses();
    }

    final selectedAddress = await showModalBottomSheet<BillingAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddressPickerBottomSheet('Billing'),
    );

    if (selectedAddress != null) {
      setState(() {
        _selectedBillingAddress = selectedAddress;
      });
    }
  }

  void _showTermsAndConditionPicker() async {
    if (_termsAndConditions.isEmpty) {
      await _loadTermsAndConditions();
    }

    final selectedTerms = await showModalBottomSheet<TermsAndConditionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTermsAndConditionPickerBottomSheet(),
    );

    if (selectedTerms != null) {
      setState(() {
        _selectedTermsAndCondition = selectedTerms;
      });
    }
  }

  void _showPaymentTermsPicker() async {
    final selectedTerms = await PaymentTermsPickerUtils.showPaymentTermsPicker(
      context: context,
      selectedTerms: _selectedPaymentTerms,
    );

    if (selectedTerms != null) {
      setState(() {
        _selectedPaymentTerms = selectedTerms;
      });
    }
  }

  // Load Data Methods
  Future<void> _loadVendors() async {
    setState(() {
      _isLoadingVendors = true;
    });

    try {
      final response = await ApiService.getSiteVendors(siteId: widget.site.id);

      if (response != null && response.status == 'success') {
        setState(() {
          _vendors = response.data;
        });
        print('Loaded ${_vendors.length} vendors');
      } else {
        print('Failed to load vendors: ${response?.message}');
      }
    } catch (e) {
      print('Error loading vendors: $e');
    } finally {
      setState(() {
        _isLoadingVendors = false;
      });
    }
  }

  Future<void> _loadBillingAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getBillingAddresses(
          apiToken: token,
          siteId: widget.site.id,
        );

        if (response != null && response.status == 1) {
          setState(() {
            _billingAddresses = response.data;
          });
        }
      }
    } catch (e) {
      print('Error loading billing addresses: $e');
    } finally {
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _loadTermsAndConditions() async {
    setState(() {
      _isLoadingTerms = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getTermsAndConditions(
          apiToken: token,
        );

        if (response != null && response.status == 1) {
          setState(() {
            _termsAndConditions = response.data;
          });
        }
      }
    } catch (e) {
      print('Error loading terms and conditions: $e');
    } finally {
      setState(() {
        _isLoadingTerms = false;
      });
    }
  }

  // Bottom Sheet Builders
  Widget _buildVendorPickerBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Vendor',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Vendors list
          Expanded(
            child: _isLoadingVendors
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Add New Vendor Option - Always shown at top
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryColor,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.add,
                            color: AppColors.primaryColor,
                          ),
                          title: Text(
                            'Add new vendor',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(); // Close vendor picker
                            _showAddVendorDialog();
                          },
                        ),
                      ),
                      
                      // Existing Vendors
                      if (_vendors.isNotEmpty) ...[
                        ..._vendors.map((vendor) => Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(vendor.name),
                            subtitle: Text(vendor.mobile),
                            onTap: () => Navigator.of(context).pop(vendor),
                          ),
                        )),
                      ] else ...[
                        // Empty state when no vendors found
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No vendors found',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add your first vendor to get started',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPickerBottomSheet(String type) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select $type Address',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showAddAddressDialog(type),
                      icon: Icon(Icons.add, color: AppColors.primaryColor),
                      tooltip: 'Add New Address',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Addresses list
          Expanded(
            child: _isLoadingAddresses
                ? Center(child: CircularProgressIndicator())
                : _billingAddresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No addresses found',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first address to get started',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddAddressDialog(type),
                          icon: Icon(Icons.add),
                          label: Text('Add Address'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _billingAddresses.length,
                    itemBuilder: (context, index) {
                      final address = _billingAddresses[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          dense: true,
                          title: Text(
                                        address.companyName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                                            children: [
                              SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                    size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        address.address,
                                      style: AppTypography.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.map,
                                        size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                      SizedBox(width: 4),
                                    Text(
                                      address.state,
                                        style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      ),
                                    ],
                                    ),
                                    if (address.gstin.isNotEmpty &&
                                      address.gstin != 'NA')
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      Icon(
                                        Icons.receipt,
                                          size: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                        SizedBox(width: 4),
                                      Text(
                                        'GSTIN: ${address.gstin}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                            fontSize: 11,
                                        ),
                                      ),
                                    ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.of(context).pop(); // Close picker first
                                _showEditAddressDialog(address);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(address),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditionPickerBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Terms and Condition',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showAddTermsDialog(),
                      icon: Icon(Icons.add, color: AppColors.primaryColor),
                      tooltip: 'Add New Terms',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Terms list
          Expanded(
            child: _isLoadingTerms
                ? Center(child: CircularProgressIndicator())
                : _termsAndConditions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No terms found',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first terms to get started',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddTermsDialog(),
                          icon: Icon(Icons.add),
                          label: Text('Add Terms'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _termsAndConditions.length,
                    itemBuilder: (context, index) {
                      final terms = _termsAndConditions[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(terms),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Terms #${terms.id}',
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),

                                    IconButton(
                                      onPressed: () {
                                        _showEditTermsDialog(terms);
                                      },
                                      icon: Icon(Icons.edit),
                                    ),
                                  ],
                                ),
                                Divider(height: 16),
                                Text(
                                  terms.termAndCondition,
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Terms Dialog Methods
  void _showAddTermsDialog() {
    final termsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Terms and Condition'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Terms and Condition',
                controller: termsController,
                hintText: 'Enter terms and condition',
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (termsController.text.trim().isEmpty) {
                SnackBarUtils.showError(
                  context,
                  message: 'Please enter terms and condition',
                );
                return;
              }

              final token = await AuthService.currentToken;
              if (token != null) {
                final response =
                    await ApiService.storeAndUpdateTermsAndCondition(
                      apiToken: token,
                      termAndCondition: termsController.text.trim(),
                    );

                if (response != null && response['status'] == 1) {
                  SnackBarUtils.showSuccess(
                    context,
                    message: 'Terms added successfully',
                  );
                  Navigator.of(context).pop();
                  await _loadTermsAndConditions();
                } else {
                  SnackBarUtils.showError(
                    context,
                    message: 'Failed to add terms',
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTermsDialog(TermsAndConditionModel terms) {
    final termsController = TextEditingController(text: terms.termAndCondition);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Terms and Condition'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Terms and Condition',
                controller: termsController,
                hintText: 'Enter terms and condition',
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (termsController.text.trim().isEmpty) {
                SnackBarUtils.showError(
                  context,
                  message: 'Please enter terms and condition',
                );
                return;
              }

              final token = await AuthService.currentToken;
              if (token != null) {
                final response =
                    await ApiService.storeAndUpdateTermsAndCondition(
                      apiToken: token,
                      termAndCondition: termsController.text.trim(),
                      termId: terms.id,
                    );

                if (response != null && response['status'] == 1) {
                  SnackBarUtils.showSuccess(
                    context,
                    message: 'Terms updated successfully',
                  );
                  Navigator.of(context).pop();
                  await _loadTermsAndConditions();
                } else {
                  SnackBarUtils.showError(
                    context,
                    message: 'Failed to update terms',
                  );
                }
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  // Address Dialog Methods
  void _showAddAddressDialog(String type) {
    final companyController = TextEditingController();
    final addressController = TextEditingController();
    final gstinController = TextEditingController();
    String? selectedState;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add $type Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Company Name',
                  controller: companyController,
                  hintText: 'Enter company name',
                ),
                SizedBox(height: 16),
                CustomTextField(
                  label: 'Address',
                  controller: addressController,
                  hintText: 'Enter full address',
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final state = await StatePickerUtils.showStatePicker(
                      context: context,
                      selectedState: selectedState,
                    );
                    if (state != null) {
                      setState(() {
                        selectedState = state;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'State',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                selectedState ?? 'Select state',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: selectedState != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
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
                CustomTextField(
                  label: 'GSTIN (Optional)',
                  controller: gstinController,
                  hintText: 'Enter GSTIN number',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (companyController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    selectedState == null) {
                  SnackBarUtils.showError(
                    context,
                    message: 'Please fill all required fields',
                  );
                  return;
                }

                final token = await AuthService.currentToken;
                if (token != null) {
                  final response = await ApiService.storeBillingAddress(
                    apiToken: token,
                    siteId: widget.site.id,
                    companyName: companyController.text,
                    address: addressController.text,
                    state: selectedState!,
                    gstin: gstinController.text.isEmpty
                        ? 'NA'
                        : gstinController.text,
                  );

                  if (response != null && response.status == 1) {
                    SnackBarUtils.showSuccess(
                      context,
                      message: 'Address added successfully',
                    );
                    Navigator.of(context).pop();
                    await _loadBillingAddresses();
                  } else {
                    SnackBarUtils.showError(
                      context,
                      message: 'Failed to add address',
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAddressDialog(BillingAddressModel address) {
    final companyController = TextEditingController(text: address.companyName);
    final addressController = TextEditingController(text: address.address);
    final gstinController = TextEditingController(
      text: address.gstin == 'NA' ? '' : address.gstin,
    );
    String? selectedState = address.state;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Company Name',
                  controller: companyController,
                  hintText: 'Enter company name',
                ),
                SizedBox(height: 16),
                CustomTextField(
                  label: 'Address',
                  controller: addressController,
                  hintText: 'Enter full address',
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final state = await StatePickerUtils.showStatePicker(
                      context: context,
                      selectedState: selectedState,
                    );
                    if (state != null) {
                      setState(() {
                        selectedState = state;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'State',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                selectedState ?? 'Select state',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: selectedState != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
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
                CustomTextField(
                  label: 'GSTIN (Optional)',
                  controller: gstinController,
                  hintText: 'Enter GSTIN number',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (companyController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    selectedState == null) {
                  SnackBarUtils.showError(
                    context,
                    message: 'Please fill all required fields',
                  );
                  return;
                }

                final token = await AuthService.currentToken;
                if (token != null) {
                  final response = await ApiService.updateBillingAddress(
                    apiToken: token,
                    addressId: address.id,
                    companyName: companyController.text,
                    address: addressController.text,
                    state: selectedState!,
                    gstin: gstinController.text.isEmpty
                        ? 'NA'
                        : gstinController.text,
                  );

                  if (response != null && response.status == 1) {
                    SnackBarUtils.showSuccess(
                      context,
                      message: 'Address updated successfully',
                    );
                    Navigator.of(context).pop();
                    await _loadBillingAddresses();
                  } else {
                    SnackBarUtils.showError(
                      context,
                      message: 'Failed to update address',
                    );
                  }
                }
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Vendor Dialog Methods
  void _showAddVendorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _VendorDialog(
          site: widget.site,
          onSuccess: () async {
            Navigator.of(context).pop();
            // Reload vendors
            await _loadVendors();
            // If a new vendor was just added, it will be in the list
            // The user can select it from the vendor picker
          },
        ),
      ),
    );
  }
}

class _VendorDialog extends StatefulWidget {
  final SiteModel site;
  final VoidCallback onSuccess;

  const _VendorDialog({
    required this.site,
    required this.onSuccess,
  });

  @override
  State<_VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends State<_VendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  
  bool _isLoading = false;
  bool _isDialogClosing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _isDialogClosing = true;
    super.dispose();
  }

  Future<void> _openNativeContacts() async {
    try {
      // Check if widget is still mounted
      if (!mounted || _isDialogClosing) return;

      // Check current permission status
      bool hasPermission = await FlutterContacts.requestPermission(readonly: true);
      
      // If permission is not granted, return silently
      if (!hasPermission) {
        if (!mounted) return;
                SnackBarUtils.showError(
                  context,
          message: 'Contacts permission denied',
                );
                return;
              }

      // Open native contact picker
      final Contact? contact = await FlutterContacts.openExternalPick();
      
      if (contact != null && mounted) {
        _selectContact(contact);
      }
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;
      
      SnackBarUtils.showError(
        context,
        message: 'Error opening contacts: ${e.toString()}',
      );
    }
  }

  void _selectContact(Contact contact) {
    setState(() {
      _nameController.text = contact.displayName;
      
      // Set first phone number
      if (contact.phones.isNotEmpty) {
        _mobileController.text = contact.phones.first.number;
      }
      
      // Set first email if available
      if (contact.emails.isNotEmpty) {
        _emailController.text = contact.emails.first.address;
      }
    });
  }

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

              try {
                final result = await ApiService.saveSiteVendor(
                  siteId: widget.site.id,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        gstNo: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
      );

      if (result != null) {
        if (result['status'] == 'success') {
                  SnackBarUtils.showSuccess(
                    context,
                    message: result['message'] ?? 'Vendor added successfully',
                  );
          widget.onSuccess();
        } else {
          SnackBarUtils.showError(
            context,
            message: result['message'] ?? 'Failed to add vendor',
          );
        }
                } else {
                  SnackBarUtils.showError(
                    context,
          message: 'Failed to add vendor',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    'Add New Vendor',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isDialogClosing = true;
                      });
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GST Number Field
                      CustomTextField(
                        controller: _gstController,
                        label: 'GST Number',
                        hintText: 'Enter GST number (optional)',
                        validator: (value) {
                          return null; // GST is optional
                        },
                      ),
                      SizedBox(height: 16),

                      // Contact Selection Section
                      GestureDetector(
                        onTap: _openNativeContacts,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.contacts,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Select from Contacts',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Name Field
                      CustomTextField(
                        controller: _nameController,
                        label: 'Name *',
                        hintText: 'Enter vendor name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter vendor name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Mobile Field
                      CustomTextField(
                        controller: _mobileController,
                        label: 'Mobile *',
                        hintText: 'Enter mobile number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter mobile number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'Enter email address (optional)',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          // Email is optional, but if provided, it must be valid
                          if (value != null && value.trim().isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isDialogClosing = true;
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Add',
                              onPressed: _isLoading ? null : _saveVendor,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20), // Bottom padding for safe area
                    ],
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
