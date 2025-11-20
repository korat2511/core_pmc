import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/date_picker_utils.dart';
import '../models/site_model.dart';
import '../models/petty_cash_entry_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/api_response.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/custom_button.dart';

class AddPettyCashEntryScreen extends StatefulWidget {
  final SiteModel site;
  final PettyCashEntryModel? entry; // For editing

  const AddPettyCashEntryScreen({
    super.key,
    required this.site,
    this.entry,
  });

  @override
  State<AddPettyCashEntryScreen> createState() => _AddPettyCashEntryScreenState();
}

class _AddPettyCashEntryScreenState extends State<AddPettyCashEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _remarkController = TextEditingController();
  final _entryDateController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _paidByController = TextEditingController();
  final _otherReceivedFromController = TextEditingController();
  final _otherPaidToController = TextEditingController();

  String _ledgerType = 'spent'; // 'spent' or 'received'
  String _paymentMode = 'cash';
  String? _receivedVia;
  String? _paidVia;
  String? _receivedFromType;
  String? _paidToType;
  
  PettyCashOptionModel? _selectedReceivedFrom;
  PettyCashOptionModel? _selectedPaidTo;
  
  List<PettyCashOptionModel> _receivedFromOptions = [];
  List<PettyCashOptionModel> _paidToOptions = [];
  bool _isLoadingOptions = false;
  
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = []; // For editing
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.entry != null) {
      final entry = widget.entry!;
      _ledgerType = entry.ledgerType;
      _amountController.text = entry.amount.toString();
      _paymentMode = entry.paymentMode;
      _transactionIdController.text = entry.transactionId ?? '';
      _remarkController.text = entry.remark ?? '';
      _entryDateController.text = entry.entryDate;
      
      if (entry.ledgerType == 'received') {
        _receivedByController.text = entry.receivedBy ?? '';
        _receivedVia = entry.receivedVia;
        _receivedFromType = entry.receivedFromType;
        _otherReceivedFromController.text = entry.receivedFromName ?? '';
        if (entry.receivedFromId != null) {
          _selectedReceivedFrom = PettyCashOptionModel(
            id: entry.receivedFromId,
            name: entry.receivedFromName ?? '',
          );
        }
        _existingImageUrls = entry.images.map((img) => img.imagePath ?? img.image).toList();
      } else {
        _paidByController.text = entry.paidBy ?? '';
        _paidVia = entry.paidVia;
        _paidToType = entry.paidToType;
        _otherPaidToController.text = entry.paidToName ?? '';
        if (entry.paidToId != null) {
          _selectedPaidTo = PettyCashOptionModel(
            id: entry.paidToId,
            name: entry.paidToName ?? '',
          );
        }
        _existingImageUrls = entry.images.map((img) => img.imagePath ?? img.image).toList();
      }
    } else {
      _entryDateController.text = DatePickerUtils.getCurrentDate(format: 'yyyy-MM-dd');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _remarkController.dispose();
    _entryDateController.dispose();
    _receivedByController.dispose();
    _paidByController.dispose();
    _otherReceivedFromController.dispose();
    _otherPaidToController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions(String type) async {
    setState(() {
      _isLoadingOptions = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.getPettyCashOptions(
        apiToken: token,
        siteId: widget.site.id,
        type: type,
      );

      if (response.status == 1 && response.data != null) {
        setState(() {
          if (type == _receivedFromType) {
            _receivedFromOptions = response.data ?? [];
          } else if (type == _paidToType) {
            _paidToOptions = response.data ?? [];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading options: $e');
    } finally {
      setState(() {
        _isLoadingOptions = false;
      });
    }
  }

  void _onReceivedFromTypeChanged(String? type) {
    setState(() {
      _receivedFromType = type;
      _selectedReceivedFrom = null;
      _otherReceivedFromController.clear();
      _receivedFromOptions = [];
    });

    if (type != null && type != 'other') {
      _loadOptions(type);
    }
  }

  void _onPaidToTypeChanged(String? type) {
    setState(() {
      _paidToType = type;
      _selectedPaidTo = null;
      _otherPaidToController.clear();
      _paidToOptions = [];
    });

    if (type != null && type != 'other') {
      _loadOptions(type);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error picking images: $e');
    }
  }

  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ledgerType == 'received' && _receivedFromType == null) {
      SnackBarUtils.showError(context, message: 'Please select received from type');
      return;
    }

    if (_ledgerType == 'spent' && _paidToType == null) {
      SnackBarUtils.showError(context, message: 'Please select paid to type');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      // Format date for API (yyyy-MM-dd)
      String entryDate = _entryDateController.text;
      if (entryDate.contains('-') && entryDate.split('-')[0].length == 2) {
        // Convert dd-MM-yyyy to yyyy-MM-dd
        final parts = entryDate.split('-');
        entryDate = '${parts[2]}-${parts[1]}-${parts[0]}';
      }

      ApiResponse response;

      if (widget.entry != null) {
        // Update existing entry
        response = await ApiService.updatePettyCashEntry(
          apiToken: token,
          entryId: widget.entry!.id,
          amount: double.parse(_amountController.text),
          entryDate: entryDate,
          paymentMode: _paymentMode,
          receivedBy: _ledgerType == 'received' ? (_receivedByController.text.isNotEmpty ? _receivedByController.text : null) : null,
          receivedVia: _ledgerType == 'received' ? _receivedVia : null,
          receivedFrom: _ledgerType == 'received' ? _receivedFromType : null,
          receivedFromType: _ledgerType == 'received' ? _receivedFromType : null,
          receivedFromId: _ledgerType == 'received' && _receivedFromType != 'other' && _receivedFromType != 'client'
              ? _selectedReceivedFrom?.id 
              : null,
          receivedFromName: _ledgerType == 'received' 
              ? (_receivedFromType == 'other' 
                  ? (_otherReceivedFromController.text.isNotEmpty ? _otherReceivedFromController.text : null)
                  : (_receivedFromType == 'client' 
                      ? widget.site.clientName 
                      : _selectedReceivedFrom?.name))
              : null,
          paidBy: _ledgerType == 'spent' ? (_paidByController.text.isNotEmpty ? _paidByController.text : null) : null,
          paidVia: _ledgerType == 'spent' ? _paidVia : null,
          paidTo: _ledgerType == 'spent' ? _paidToType : null,
          paidToType: _ledgerType == 'spent' ? _paidToType : null,
          paidToId: _ledgerType == 'spent' && _paidToType != 'other' && _paidToType != 'client'
              ? _selectedPaidTo?.id 
              : null,
          paidToName: _ledgerType == 'spent' 
              ? (_paidToType == 'other' 
                  ? (_otherPaidToController.text.isNotEmpty ? _otherPaidToController.text : null)
                  : (_paidToType == 'client' 
                      ? widget.site.clientName 
                      : _selectedPaidTo?.name))
              : null,
          transactionId: _transactionIdController.text.isNotEmpty 
              ? _transactionIdController.text 
              : null,
          remark: _remarkController.text.isNotEmpty ? _remarkController.text : null,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
      } else {
        // Create new entry
        response = await ApiService.createPettyCashEntry(
          apiToken: token,
          siteId: widget.site.id,
          ledgerType: _ledgerType,
          amount: double.parse(_amountController.text),
          paymentMode: _paymentMode,
          entryDate: entryDate,
          receivedBy: _ledgerType == 'received' ? (_receivedByController.text.isNotEmpty ? _receivedByController.text : null) : null,
          receivedVia: _ledgerType == 'received' ? _receivedVia : null,
          receivedFrom: _ledgerType == 'received' ? _receivedFromType : null,
          receivedFromType: _ledgerType == 'received' ? _receivedFromType : null,
          receivedFromId: _ledgerType == 'received' && _receivedFromType != 'other' && _receivedFromType != 'client'
              ? _selectedReceivedFrom?.id 
              : null,
          receivedFromName: _ledgerType == 'received' 
              ? (_receivedFromType == 'other' 
                  ? (_otherReceivedFromController.text.isNotEmpty ? _otherReceivedFromController.text : null)
                  : (_receivedFromType == 'client' 
                      ? widget.site.clientName 
                      : _selectedReceivedFrom?.name))
              : null,
          paidBy: _ledgerType == 'spent' ? (_paidByController.text.isNotEmpty ? _paidByController.text : null) : null,
          paidVia: _ledgerType == 'spent' ? _paidVia : null,
          paidTo: _ledgerType == 'spent' ? _paidToType : null,
          paidToType: _ledgerType == 'spent' ? _paidToType : null,
          paidToId: _ledgerType == 'spent' && _paidToType != 'other' && _paidToType != 'client'
              ? _selectedPaidTo?.id 
              : null,
          paidToName: _ledgerType == 'spent' 
              ? (_paidToType == 'other' 
                  ? (_otherPaidToController.text.isNotEmpty ? _otherPaidToController.text : null)
                  : (_paidToType == 'client' 
                      ? widget.site.clientName 
                      : _selectedPaidTo?.name))
              : null,
          transactionId: _transactionIdController.text.isNotEmpty 
              ? _transactionIdController.text 
              : null,
          remark: _remarkController.text.isNotEmpty ? _remarkController.text : null,
          imageFiles: _selectedImages,
        );
      }

      if (response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message,
        );
        NavigationUtils.pop(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message,
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error saving entry: $e',
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.entry != null ? 'Edit Petty Cash Entry' : 'Add Petty Cash Entry',
        showDrawer: false,
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ledger Type - Segmented Control Style
            _buildLedgerTypeSelector(),
            const SizedBox(height: 24),

            // Amount
            CustomTextField(
              controller: _amountController,
              label: 'Amount *',
              hintText: 'Enter amount',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Amount is required';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Entry Date
            CustomDatePickerField(
              controller: _entryDateController,
              label: 'Entry Date *',
              format: 'yyyy-MM-dd',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Entry date is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Mode
            _buildDropdownField<String>(
              label: 'Payment Mode *',
              value: _paymentMode,
              items: ['cash', 'bank', 'upi', 'other']
                  .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _paymentMode = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Conditional fields based on ledger type
            if (_ledgerType == 'received') ..._buildReceivedFields(),
            if (_ledgerType == 'spent') ..._buildSpentFields(),

            // Transaction ID
            CustomTextField(
              controller: _transactionIdController,
              label: 'Transaction ID',
              hintText: 'Enter transaction ID (optional)',
            ),
            const SizedBox(height: 16),

            // Remark
            CustomTextField(
              controller: _remarkController,
              label: 'Remark',
              hintText: 'Enter remark (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Images
            _buildImageSection(),
            const SizedBox(height: 16),

            // Save Button
            CustomButton(
              text: _isSaving ? 'Saving...' : 'Save Entry',
              onPressed: _isSaving ? null : _saveEntry,
            ),
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }

  List<Widget> _buildReceivedFields() {
    return [
      CustomTextField(
        controller: _receivedByController,
        label: 'Received By',
        hintText: 'Enter name',
      ),
      const SizedBox(height: 16),

      // Received Via
      _buildDropdownField<String>(
        label: 'Received Via',
        value: _receivedVia,
        items: ['cash', 'bank', 'upi', 'other']
            .map((via) => DropdownMenuItem(
                  value: via,
                  child: Text(via.toUpperCase()),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _receivedVia = value;
          });
        },
      ),
      const SizedBox(height: 16),

      // Received From Type
      _buildDropdownField<String>(
        label: 'Received From *',
        value: _receivedFromType,
        items: [
          'site_engineer',
          'project_coordinator',
          'agency',
          'vendor',
          'client',
          'other'
        ]
            .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(_formatTypeName(type)),
                ))
            .toList(),
        onChanged: _onReceivedFromTypeChanged,
        validator: (value) {
          if (value == null) {
            return 'Please select received from';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Received From Selection
      if (_receivedFromType != null && _receivedFromType != 'other')
        Column(
          children: [
            _buildOptionSelector(
              label: 'Select ${_formatTypeName(_receivedFromType!)}',
              options: _receivedFromOptions,
              selected: _selectedReceivedFrom,
              isLoading: _isLoadingOptions,
              onSelected: (option) {
                setState(() {
                  _selectedReceivedFrom = option;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),

      if (_receivedFromType == 'other')
        Column(
          children: [
            CustomTextField(
              controller: _otherReceivedFromController,
              label: 'Received From Name *',
              hintText: 'Enter name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter received from name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
    ];
  }

  List<Widget> _buildSpentFields() {
    return [
      CustomTextField(
        controller: _paidByController,
        label: 'Paid By',
        hintText: 'Enter name',
      ),
      const SizedBox(height: 16),

      // Paid Via
      _buildDropdownField<String>(
        label: 'Paid Via',
        value: _paidVia,
        items: ['cash', 'bank', 'upi', 'other']
            .map((via) => DropdownMenuItem(
                  value: via,
                  child: Text(via.toUpperCase()),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _paidVia = value;
          });
        },
      ),
      const SizedBox(height: 16),

      // Paid To Type
      _buildDropdownField<String>(
        label: 'Paid To *',
        value: _paidToType,
        items: [
          'site_engineer',
          'project_coordinator',
          'agency',
          'vendor',
          'client',
          'other'
        ]
            .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(_formatTypeName(type)),
                ))
            .toList(),
        onChanged: _onPaidToTypeChanged,
        validator: (value) {
          if (value == null) {
            return 'Please select paid to';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Paid To Selection
      if (_paidToType != null && _paidToType != 'other')
        Column(
          children: [
            _buildOptionSelector(
              label: 'Select ${_formatTypeName(_paidToType!)}',
              options: _paidToOptions,
              selected: _selectedPaidTo,
              isLoading: _isLoadingOptions,
              onSelected: (option) {
                setState(() {
                  _selectedPaidTo = option;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),

      if (_paidToType == 'other')
        Column(
          children: [
            CustomTextField(
              controller: _otherPaidToController,
              label: 'Paid To Name *',
              hintText: 'Enter name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter paid to name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
    ];
  }

  Widget _buildOptionSelector({
    required String label,
    required List<PettyCashOptionModel> options,
    required PettyCashOptionModel? selected,
    required bool isLoading,
    required Function(PettyCashOptionModel) onSelected,
  }) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
        ],
      );
    }

    return _buildDropdownField<PettyCashOptionModel>(
      label: label,
      value: selected,
      items: options
          .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option.name),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onSelected(value);
        }
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onTap: () {
        // Dismiss keyboard when dropdown is tapped
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      style: AppTypography.bodyLarge.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.primary,
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildLedgerTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLedgerTypeButton(
              label: 'Spent',
              value: 'spent',
              icon: Icons.arrow_upward,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildLedgerTypeButton(
              label: 'Received',
              value: 'received',
              icon: Icons.arrow_downward,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTypeButton({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _ledgerType == value;
    return InkWell(
      onTap: () {
        // Dismiss keyboard when changing ledger type
        FocusScope.of(context).unfocus();
        setState(() {
          _ledgerType = value;
          if (value == 'spent') {
            _paidToType = null;
            _selectedPaidTo = null;
            _paidToOptions = [];
            _otherPaidToController.clear();
          } else {
            _receivedFromType = null;
            _selectedReceivedFrom = null;
            _receivedFromOptions = [];
            _otherReceivedFromController.clear();
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate, size: 20),
          label: const Text('Add Images'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._existingImageUrls.asMap().entries.map((entry) {
                return _buildImageThumbnail(
                  imageUrl: entry.value,
                  index: entry.key,
                  isExisting: true,
                );
              }),
              ..._selectedImages.asMap().entries.map((entry) {
                return _buildImageThumbnail(
                  imageFile: entry.value,
                  index: entry.key,
                  isExisting: false,
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildImageThumbnail({
    String? imageUrl,
    File? imageFile,
    required int index,
    required bool isExisting,
  }) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.broken_image,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  )
                : imageFile != null
                    ? Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(index, isExisting: isExisting),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }


  String _formatTypeName(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

