import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/image_picker_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/site_user_model.dart';
import '../models/site_vendor_model.dart';
import '../models/site_agency_model.dart';
import '../services/petty_cash_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class AddPettyCashEntryScreen extends StatefulWidget {
  final SiteModel site;

  const AddPettyCashEntryScreen({super.key, required this.site});

  @override
  State<AddPettyCashEntryScreen> createState() => _AddPettyCashEntryScreenState();
}

class _AddPettyCashEntryScreenState extends State<AddPettyCashEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _paidByController = TextEditingController();
  final _receivedFromController = TextEditingController();
  final _paidToController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _otherController = TextEditingController();
  final _remarkController = TextEditingController();

  String _selectedLedgerType = 'received';
  String _selectedReceivedVia = 'cash';
  String _selectedPaidVia = 'cash';
  String _selectedPaidTo = 'site_engineer';
  DateTime _selectedDate = DateTime.now();
  List<File> _selectedImages = [];
  bool _isLoading = false;
  
  // Dynamic data
  List<SiteUserModel> _siteUsers = [];
  List<SiteVendorModel> _siteVendors = [];
  List<SiteAgencyModel> _siteAgencies = [];
  bool _isLoadingData = false;
  
  // Selected recipient data
  int? _selectedUserId;
  String? _selectedUserName;
  int? _selectedVendorId;
  String? _selectedVendorName;
  int? _selectedAgencyId;
  String? _selectedAgencyName;

  final List<String> _paymentMethods = [
    'cash',
    'bank_transfer',
    'cheque',
    'upi',
    'credit_card',
    'other',
  ];

  final List<String> _paidToOptions = [
    'site_engineer',
    'project_co_ordinator',
    'agency',
    'vendor',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadSiteData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receivedByController.dispose();
    _paidByController.dispose();
    _receivedFromController.dispose();
    _paidToController.dispose();
    _transactionIdController.dispose();
    _otherController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Add Petty Cash Entry',
          showDrawer: false,
          showBackButton: true,
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ledger Type Selection
                _buildLedgerTypeSection(),
                SizedBox(height: 16),

                // Amount Field
                _buildAmountField(),
                SizedBox(height: 16),

                // Date Field
                _buildDateField(),
                SizedBox(height: 16),

                // Conditional Fields based on Ledger Type
                if (_selectedLedgerType == 'received') ...[
                  _buildReceivedFields(),
                ] else ...[
                  _buildSpentFields(),
                ],

                SizedBox(height: 16),

                // Images Section
                _buildImagesSection(),
                SizedBox(height: 16),

                // Remark Field
                _buildRemarkField(),
                SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Save Entry',
                    onPressed: _saveEntry,
                    isLoading: _isLoading,
                    backgroundColor: AppColors.primaryColor,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildLedgerTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ledger Type',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedLedgerType = 'received'),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedLedgerType == 'received'
                        ? AppColors.successColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedLedgerType == 'received'
                          ? AppColors.successColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: _selectedLedgerType == 'received'
                            ? AppColors.successColor
                            : Colors.grey[600],
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Received',
                        style: AppTypography.titleSmall.copyWith(
                          color: _selectedLedgerType == 'received'
                              ? AppColors.successColor
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedLedgerType = 'spent'),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedLedgerType == 'spent'
                        ? AppColors.errorColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedLedgerType == 'spent'
                          ? AppColors.errorColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: _selectedLedgerType == 'spent'
                            ? AppColors.errorColor
                            : Colors.grey[600],
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Spent',
                        style: AppTypography.titleSmall.copyWith(
                          color: _selectedLedgerType == 'spent'
                              ? AppColors.errorColor
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount (₹)',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixText: '₹ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter valid amount';
            }
            if (double.parse(value) <= 0) {
              return 'Amount must be greater than 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entry Date',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: AppTypography.bodyLarge,
                ),
                Icon(Icons.calendar_today, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceivedFields() {
    return Column(
      children: [
        _buildTextField(
          'Received By',
          _receivedByController,
          'Enter person who received the amount',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter who received the amount';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildDropdownField(
          'Received Via',
          _selectedReceivedVia,
          (value) => setState(() => _selectedReceivedVia = value!),
          _paymentMethods,
        ),
        SizedBox(height: 16),
        _buildTextField(
          'Received From',
          _receivedFromController,
          'Enter source of the amount',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter source of the amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSpentFields() {
    return Column(
      children: [
        _buildTextField(
          'Paid By',
          _paidByController,
          'Enter person who paid the amount',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter who paid the amount';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildDropdownField(
          'Paid Via',
          _selectedPaidVia,
          (value) => setState(() => _selectedPaidVia = value!),
          _paymentMethods,
        ),
        SizedBox(height: 16),
        
        // Transaction ID field for non-cash payments
        if (_selectedPaidVia != 'cash' && _selectedPaidVia != 'other') ...[
          _buildTextField(
            'Transaction ID',
            _transactionIdController,
            'Enter transaction ID or reference number',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter transaction ID';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
        ],
        
        _buildDropdownField(
          'Paid To',
          _selectedPaidTo,
          (value) => setState(() => _selectedPaidTo = value!),
          _paidToOptions,
          displayText: (item) {
            switch (item) {
              case 'site_engineer': return 'Site Engineer';
              case 'project_co_ordinator': return 'Project Co Ordinator';
              case 'agency': return 'Agency';
              case 'vendor': return 'Vendor';
              case 'other': return 'Other';
              default: return item.replaceAll('_', ' ').toUpperCase();
            }
          },
        ),
        SizedBox(height: 16),
        
        // Conditional fields based on Paid To selection
        _buildPaidToConditionalFields(),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hintText, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    Function(String?) onChanged,
    List<String> items, {
    String Function(String)? displayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    displayText != null ? displayText(item) : item.replaceAll('_', ' ').toUpperCase(),
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt Images (Optional)',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Upload images of receipts or documents related to this transaction',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: _selectImages,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primaryColor,
                style: BorderStyle.solid,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.primaryColor.withOpacity(0.05),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  _selectedImages.isEmpty ? 'Add Images' : 'Add More Images',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remark (Optional)',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _remarkController,
          maxLines: 3,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'Add any additional notes or remarks',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPaidToConditionalFields() {
    switch (_selectedPaidTo) {
      case 'site_engineer':
      case 'project_co_ordinator':
        return _buildUserSelection();
      case 'agency':
        return _buildAgencySelection();
      case 'vendor':
        return _buildVendorSelection();
      case 'other':
        return _buildOtherField();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildUserSelection() {
    if (_isLoadingData) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_siteUsers.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'No users found for this site',
          style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select User',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedUserId,
              isExpanded: true,
              hint: Text('Select user'),
              onChanged: (value) {
                setState(() {
                  _selectedUserId = value;
                  final user = _siteUsers.firstWhere((user) => user.id == value);
                  _selectedUserName = '${user.firstName} ${user.lastName}';
                  _paidToController.text = _selectedUserName!;
                });
              },
              items: _siteUsers.map((user) {
                return DropdownMenuItem<int>(
                  value: user.id,
                  child: Text(
                    '${user.firstName} ${user.lastName}',
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgencySelection() {
    if (_isLoadingData) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_siteAgencies.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'No agencies found for this site',
          style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Agency',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedAgencyId,
              isExpanded: true,
              hint: Text('Select agency'),
              onChanged: (value) {
                setState(() {
                  _selectedAgencyId = value;
                  final agency = _siteAgencies.firstWhere((agency) => agency.id == value);
                  _selectedAgencyName = agency.name;
                  _paidToController.text = _selectedAgencyName!;
                });
              },
              items: _siteAgencies.map((agency) {
                return DropdownMenuItem<int>(
                  value: agency.id,
                  child: Text(
                    agency.name,
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorSelection() {
    if (_isLoadingData) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_siteVendors.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'No vendors found for this site',
          style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Vendor',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedVendorId,
              isExpanded: true,
              hint: Text('Select vendor'),
              onChanged: (value) {
                setState(() {
                  _selectedVendorId = value;
                  final vendor = _siteVendors.firstWhere((vendor) => vendor.id == value);
                  _selectedVendorName = vendor.name;
                  _paidToController.text = _selectedVendorName!;
                });
              },
              items: _siteVendors.map((vendor) {
                return DropdownMenuItem<int>(
                  value: vendor.id,
                  child: Text(
                    vendor.name,
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherField() {
    return _buildTextField(
      'Other',
      _otherController,
      'Enter other recipient',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter recipient';
        }
        return null;
      },
    );
  }

  Future<void> _loadSiteData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load site users
      final usersResponse = await ApiService.getUsersBySite(
        apiToken: (await AuthService.currentToken) ?? '',
        siteId: widget.site.id,
      );
      
      if (usersResponse.isSuccess && mounted) {
        setState(() {
          _siteUsers = usersResponse.users;
        });
      }

      // Load site agencies
      final agenciesResponse = await ApiService.getSiteAgency(siteId: widget.site.id);
      if (agenciesResponse != null && agenciesResponse.status == 'success' && mounted) {
        setState(() {
          _siteAgencies = agenciesResponse.data;
        });
      }

      // Load site vendors
      final vendorsResponse = await ApiService.getSiteVendors(siteId: widget.site.id);
      if (vendorsResponse != null && vendorsResponse.status == 'success' && mounted) {
        setState(() {
          _siteVendors = vendorsResponse.data;
        });
      }
    } catch (e) {
      print('Error loading site data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectImages() async {
    final images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: true,
      maxImages: 5,
    );
    if (images.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _saveEntry() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Prepare recipient data based on Paid To selection
      String? paidToType;
      int? paidToId;
      String? paidToName;
      String? otherRecipient;
      
      if (_selectedLedgerType == 'spent') {
        paidToType = _selectedPaidTo;
        
        switch (_selectedPaidTo) {
          case 'site_engineer':
          case 'project_co_ordinator':
            paidToId = _selectedUserId;
            paidToName = _selectedUserName;
            break;
          case 'agency':
            paidToId = _selectedAgencyId;
            paidToName = _selectedAgencyName;
            break;
          case 'vendor':
            paidToId = _selectedVendorId;
            paidToName = _selectedVendorName;
            break;
          case 'other':
            otherRecipient = _otherController.text;
            break;
        }
      }

      await PettyCashService.addPettyCashEntry(
        siteId: widget.site.id.toString(),
        siteName: widget.site.name,
        ledgerType: _selectedLedgerType,
        amount: double.parse(_amountController.text),
        receivedBy: _receivedByController.text,
        paidBy: _paidByController.text,
        receivedVia: _selectedReceivedVia,
        paidVia: _selectedPaidVia,
        receivedFrom: _receivedFromController.text,
        paidTo: _paidToController.text,
        transactionId: _selectedPaidVia != 'cash' && _selectedPaidVia != 'other' 
            ? _transactionIdController.text 
            : null,
        paidToType: paidToType,
        paidToId: paidToId,
        paidToName: paidToName,
        otherRecipient: otherRecipient,
        imageFiles: _selectedImages,
        remark: _remarkController.text,
        entryDate: _selectedDate,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, message: 'Petty cash entry added successfully!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, message: 'Failed to add entry: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
