import 'package:core_pmc/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/po_detail_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';

class RecordGrnScreen extends StatefulWidget {
  final PODetailModel poDetail;
  final PendingItem pendingItem;
  final String receivedQuantity;

  const RecordGrnScreen({
    super.key,
    required this.poDetail,
    required this.pendingItem,
    required this.receivedQuantity,
  });

  @override
  State<RecordGrnScreen> createState() => _RecordGrnScreenState();
}

class _RecordGrnScreenState extends State<RecordGrnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _grnIdController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _totalInvoiceAmountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _deliveryChallanController = TextEditingController();
  
  String? _generatedGrnId;
  bool _isLoading = false;
  bool _isGeneratingId = false;
  bool _showDeliveryChallan = false;

  @override
  void initState() {
    super.initState();
    _generateGrnId();
  }

  @override
  void dispose() {
    _grnIdController.dispose();
    _invoiceNumberController.dispose();
    _totalInvoiceAmountController.dispose();
    _remarksController.dispose();
    _deliveryChallanController.dispose();
    super.dispose();
  }

  Future<void> _generateGrnId() async {
    setState(() {
      _isGeneratingId = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        setState(() {
          _isGeneratingId = false;
        });
        return;
      }

      final response = await ApiService.generateOrderId(
        apiToken: user.apiToken,
        type: 'grn',
      );
      
      if (response.status == 1) {
        setState(() {
          _generatedGrnId = response.data?['order_id'] ?? 'GRN000001';
          _grnIdController.text = _generatedGrnId!;
        });
      } else {
        setState(() {
          _generatedGrnId = 'GRN000001';
          _grnIdController.text = _generatedGrnId!;
        });
      }
    } catch (e) {
      setState(() {
        _generatedGrnId = 'GRN000001';
        _grnIdController.text = _generatedGrnId!;
      });
    } finally {
      setState(() {
        _isGeneratingId = false;
      });
    }
  }

  Future<void> _addPhotos() async {
    // TODO: Implement photo picker functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo picker functionality will be implemented'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveGrn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final grnMaterials = [
        {
          'material_id': widget.pendingItem.materialId,
          'quantity': int.parse(widget.receivedQuantity),
        }
      ];

      final response = await ApiService.saveGrn(
        grnDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        grnNumber: _grnIdController.text,
        deliveryChallanNumber: _showDeliveryChallan ? _deliveryChallanController.text : 'INV000001',
        poId: widget.poDetail.id,
        vendorId: widget.poDetail.vendorId ?? 1,
        siteId: widget.poDetail.siteId,
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        grnMaterials: grnMaterials,
      );


      print("GRN Response == ${response}");
      print("GRN Response Status == ${response?.status}");
      print("GRN Response Message == ${response?.message}");

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(context, message: "GRN saved successfully!");
        
        // Navigate back
        Navigator.of(context).pop(true);
      } else {
        // Show the actual error message from the API
        SnackBarUtils.showError(
          context, 
          message: response?.message ?? "Failed to save GRN"
        );
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
        title: 'GRN',
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
                // GRN ID Field
                Text(
                  'GRN ID*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _grnIdController,
                        decoration: InputDecoration(
                          hintText: 'GRN000001',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter GRN ID';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: _isGeneratingId ? null : _generateGrnId,
                      icon: _isGeneratingId
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.settings, color: Colors.grey[600]),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Invoice Number Field
                Text(
                  'Invoice Number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _invoiceNumberController,
                  decoration: InputDecoration(
                    hintText: 'Enter here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                SizedBox(height: 24),

                // Total Invoice Amount Field
                Text(
                  'Total Invoice Amount (Inclusive of GST)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _totalInvoiceAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter here',
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
                    hintText: 'Add remark',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                SizedBox(height: 24),

                // Delivery Challan Number
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDeliveryChallan = !_showDeliveryChallan;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delivery Challan Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showDeliveryChallan) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _deliveryChallanController,
                    decoration: InputDecoration(
                      hintText: 'Enter delivery challan number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],

                SizedBox(height: 32),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGrn,
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
                            'Done',
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
