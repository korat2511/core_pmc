import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
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

class CreatePOScreen extends StatefulWidget {
  final SiteModel site;

  const CreatePOScreen({
    super.key,
    required this.site,
  });

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
      final response = await ApiService.getMaterials(page: 1);
      
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
                   material.brandName?.toLowerCase().contains(query.toLowerCase()) == true;
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
        _unitPriceControllers[materialId] = TextEditingController(text: material.unitPrice);
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
          if (quantity == null || quantity.isEmpty || double.tryParse(quantity) == null) {
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
        _currentStep--;
      });
    }
  }

  double _calculateTotalPrice(int materialId) {
    final quantity = double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '') ?? 0;
    final unitPrice = double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '') ?? 0;
    final discount = double.tryParse(_discountControllers[materialId]?.text.trim() ?? '') ?? 0;
    final tax = double.tryParse(_taxControllers[materialId]?.text.trim() ?? '') ?? 0;

    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    final taxableValue = subtotal - discountAmount;
    final taxAmount = taxableValue * (tax / 100);
    final total = taxableValue + taxAmount;

    return total;
  }

  double _calculateTotalTaxableValue(int materialId) {
    final quantity = double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '') ?? 0;
    final unitPrice = double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '') ?? 0;
    final discount = double.tryParse(_discountControllers[materialId]?.text.trim() ?? '') ?? 0;

    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    return subtotal - discountAmount;
  }

  double _calculateTaxAmount(int materialId) {
    final taxableValue = _calculateTotalTaxableValue(materialId);
    final tax = double.tryParse(_taxControllers[materialId]?.text.trim() ?? '') ?? 0;
    return taxableValue * (tax / 100);
  }

  double _calculateDiscountAmount(int materialId) {
    final quantity = double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '') ?? 0;
    final unitPrice = double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '') ?? 0;
    final discount = double.tryParse(_discountControllers[materialId]?.text.trim() ?? '') ?? 0;

    final subtotal = quantity * unitPrice;
    return subtotal * (discount / 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Purchase Order',
        showBackButton: true,
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
                              color: isActive ? AppColors.primaryColor : AppColors.textSecondary,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
                            color: isCompleted ? AppColors.primaryColor : AppColors.borderColor,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Step Content
          Expanded(
            child: _buildStepContent(),
          ),

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
                        ? (_currentStep == _numSteps - 1 ? _createPO : _nextStep)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          SizedBox(height: 8,),
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: CustomSearchBar(
              hintText: 'Search materials...',
              onChanged: _filterMaterials,
              controller: _materialSearchController,
            ),
          ),
          Expanded(
          child: _isLoadingMaterials
              ? Center(child: CircularProgressIndicator())
              : _filteredMaterials.isEmpty
                  ? Center(
                      child: Text(
                        'No materials found',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: ResponsiveUtils.responsivePadding(context),
                      itemCount: _filteredMaterials.length,
                      itemBuilder: (context, index) {
                        final material = _filteredMaterials[index];
                        final isSelected = _selectedMaterialIds.contains(material.id);
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (value) => _toggleMaterialSelection(material.id),
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
    ));
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
                         label: 'Ordered Quantity (${material.unitOfMeasurement})',
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
                      _buildCalculationRow('Subtotal', '₹${(double.tryParse(_quantityControllers[materialId]?.text.trim() ?? '0') ?? 0) * (double.tryParse(_unitPriceControllers[materialId]?.text.trim() ?? '0') ?? 0)}'),
                      _buildCalculationRow('Discount', '-₹${_calculateDiscountAmount(materialId).toStringAsFixed(2)}'),
                      _buildCalculationRow('Taxable Value', '₹${_calculateTotalTaxableValue(materialId).toStringAsFixed(2)}'),
                      _buildCalculationRow('Tax', '₹${_calculateTaxAmount(materialId).toStringAsFixed(2)}'),
                      Divider(),
                      _buildCalculationRow('Total Price', '₹${_calculateTotalPrice(materialId).toStringAsFixed(2)}', isTotal: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ));
  }

  Widget _buildCalculationRow(String label, String value, {bool isTotal = false}) {
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
            CustomTextField(
              label: 'Purchase Order ID*',
              controller: _purchaseOrderIdController,
              hintText: 'Enter purchase order ID',
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
                            _selectedDeliveryAddress?.address ?? 'Select delivery address',
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
                            _selectedBillingAddress?.address ?? 'Select billing address',
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
                            _selectedTermsAndCondition?.termAndCondition ?? 'Select terms and condition',
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
          ],
        ),
      ),
    );
  }

  void _createPO() {
    SnackBarUtils.showSuccess(context, message: "Purchase Order created successfully!");
    Navigator.of(context).pop();
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
      final response = await ApiService.getSiteVendors(
        siteId: widget.site.id,
      );
      
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
                : _vendors.isEmpty
                    ? Center(child: Text('No vendors found'))
                    : ListView.builder(
                        itemCount: _vendors.length,
                        itemBuilder: (context, index) {
                          final vendor = _vendors[index];
                          return ListTile(
                            title: Text(vendor.name),
                            subtitle: Text(vendor.mobile),
                            onTap: () => Navigator.of(context).pop(vendor),
                          );
                        },
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
                            Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
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
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _billingAddresses.length,
                        itemBuilder: (context, index) {
                          final address = _billingAddresses[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(address),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            address.companyName,
                                            style: AppTypography.titleSmall.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
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
                                      ],
                                    ),
                                    Divider(height: 16),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            address.address,
                                            style: AppTypography.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.map, size: 16, color: AppColors.textSecondary),
                                        SizedBox(width: 8),
                                        Text(
                                          address.state,
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (address.gstin.isNotEmpty && address.gstin != 'NA') ...[
                                          SizedBox(width: 16),
                                          Icon(Icons.receipt, size: 16, color: AppColors.textSecondary),
                                          SizedBox(width: 8),
                                          Text(
                                            'GSTIN: ${address.gstin}',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
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
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Terms list
          Expanded(
            child: _isLoadingTerms
                ? Center(child: CircularProgressIndicator())
                : _termsAndConditions.isEmpty
                    ? Center(child: Text('No terms found'))
                    : ListView.builder(
                        itemCount: _termsAndConditions.length,
                        itemBuilder: (context, index) {
                          final terms = _termsAndConditions[index];
                          return ListTile(
                            title: Text(terms.termAndCondition),
                            subtitle: Text('ID: ${terms.id}'),
                            onTap: () => Navigator.of(context).pop(terms),
                          );
                        },
                      ),
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
                        Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
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
                SnackBarUtils.showError(context, message: 'Please fill all required fields');
                return;
              }

              final token = await AuthService.currentToken;
              if (token != null) {
                final response = await ApiService.storeBillingAddress(
                  apiToken: token,
                  companyName: companyController.text,
                  address: addressController.text,
                  state: selectedState!,
                  gstin: gstinController.text.isEmpty ? 'NA' : gstinController.text,
                );

                if (response != null && response.status == 1) {
                  SnackBarUtils.showSuccess(context, message: 'Address added successfully');
                  Navigator.of(context).pop();
                  await _loadBillingAddresses();
                } else {
                  SnackBarUtils.showError(context, message: 'Failed to add address');
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    ));
  }

  void _showEditAddressDialog(BillingAddressModel address) {
    final companyController = TextEditingController(text: address.companyName);
    final addressController = TextEditingController(text: address.address);
    final gstinController = TextEditingController(text: address.gstin == 'NA' ? '' : address.gstin);
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
                        Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
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
                SnackBarUtils.showError(context, message: 'Please fill all required fields');
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
                  gstin: gstinController.text.isEmpty ? 'NA' : gstinController.text,
                );

                if (response != null && response.status == 1) {
                  SnackBarUtils.showSuccess(context, message: 'Address updated successfully');
                  Navigator.of(context).pop();
                  await _loadBillingAddresses();
                } else {
                  SnackBarUtils.showError(context, message: 'Failed to update address');
                }
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    ));
  }
}
