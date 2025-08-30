import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/po_detail_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';

class RecordAdvanceScreen extends StatefulWidget {
  final PODetailModel poDetail;

  const RecordAdvanceScreen({
    super.key,
    required this.poDetail,
  });

  @override
  State<RecordAdvanceScreen> createState() => _RecordAdvanceScreenState();
}

class _RecordAdvanceScreenState extends State<RecordAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paidAmountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _remarksController = TextEditingController();
  
  String _selectedPaymentMode = 'cash';
  DateTime _selectedDate = DateTime.now();
  String? _generatedAdvanceId;
  bool _isLoading = false;
  bool _isGeneratingId = false;

  final List<String> _paymentModes = [
    'cash',
    'bank_transfer',
    'cheque',
    'upi',
    'card',
  ];

  @override
  void initState() {
    super.initState();
    _generateAdvanceId();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _transactionIdController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _generateAdvanceId() async {
    setState(() {
      _isGeneratingId = true;
    });


    try {

      final user = AuthService.currentUser;
      if (user == null) {
        setState(() {
          _isGeneratingId = false;
        });
      }

      final response = await ApiService.generateOrderId(
          apiToken: user!.apiToken,
          type: 'advance');
      
      if (response.status == 1) {
        setState(() {
          _generatedAdvanceId = response.data?['order_id'] ?? 'ADV00001';
        });
      } else {
        setState(() {
          _generatedAdvanceId = 'ADV00001';
        });
      }
    } catch (e) {
      setState(() {
        _generatedAdvanceId = 'ADV00001';
      });
    } finally {
      setState(() {
        _isGeneratingId = false;
      });
    }
  }

  double get _totalAdvancePaid {
    return widget.poDetail.poPayment.fold(0.0, (sum, payment) => 
      sum + (double.tryParse(payment.paymentAmount) ?? 0.0));
  }

  double get _remainingAmount {
    final grandTotal = double.tryParse(widget.poDetail.grandTotal) ?? 0.0;
    return grandTotal - _totalAdvancePaid;
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.0', 'en_IN').format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _recordAdvance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.storePayment(
        poId: widget.poDetail.id,
        grnId: null,
        paymentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        paymentAmount: _paidAmountController.text,
        paymentMode: _selectedPaymentMode,
        remark: _remarksController.text.isEmpty ? null : _remarksController.text,
        transactionId: _transactionIdController.text.isEmpty ? null : _transactionIdController.text,
        advanceId: _generatedAdvanceId ?? 'ADV00001',
      );

      if (response != null && response.status == 1) {
        // Show success message
        SnackBarUtils.showSuccess(context, message: "Advance payment recorded successfully!");

        
        // Navigate back
        Navigator.of(context).pop(true);
      } else {
        SnackBarUtils.showError(context, message: "Failed to record advance payment");

      }
    } catch (e) {
      SnackBarUtils.showError(context, message: "Error: ${e.toString()}");

    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Record New Advance',
        showDrawer: false,
        showBackButton: true,
      ),

      body: GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Information Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PO amount:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '₹${_formatCurrency(double.tryParse(widget.poDetail.grandTotal) ?? 0.0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PO ID:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.poDetail.purchaseOrderId,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Information Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₹${_formatCurrency(_totalAdvancePaid)} Advance has been recorded so far on this order.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Paid Amount Field
              Text(
                'Paid Amount*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter paid amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > _remainingAmount) {
                    return 'Amount cannot exceed remaining balance of ₹${_formatCurrency(_remainingAmount)}';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Text(
                'You can add paid amount up to ₹${_formatCurrency(_remainingAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 24),

              // Mode of Payment Field
              Text(
                'Mode of Payment*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPaymentMode,
                    isExpanded: true,
                    items: _paymentModes.map((String mode) {
                      return DropdownMenuItem<String>(
                        value: mode,
                        child: Text(
                          mode.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPaymentMode = newValue!;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Paid On Field
              Text(
                'Paid On*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Transaction ID Field
              Text(
                'Transaction ID',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _transactionIdController,
                decoration: InputDecoration(
                  hintText: 'Enter ID (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),

              SizedBox(height: 24),

              // Remarks Field
              Text(
                'Remarks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for payment. E.g. Paid advance...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),

              SizedBox(height: 32),

              // Record Advance Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _recordAdvance,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Record advance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
