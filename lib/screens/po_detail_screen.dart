import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../models/po_detail_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import 'grn_detail_screen.dart';
import 'payment_detail_screen.dart';
import 'record_advance_screen.dart';
import 'record_grn_screen.dart';

class PODetailScreen extends StatefulWidget {
  final int materialPoId;
  final String poNumber;

  const PODetailScreen({
    super.key,
    required this.materialPoId,
    required this.poNumber,
  });

  @override
  State<PODetailScreen> createState() => _PODetailScreenState();
}

class _PODetailScreenState extends State<PODetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PODetailModel? _poDetail;
  bool _isLoading = true;
  String? _errorMessage;
  final _receivedQuantityController = TextEditingController();
  bool _isExpandedPayments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPODetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receivedQuantityController.dispose();
    super.dispose();
  }

  Future<void> _loadPODetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getPODetail(
        materialPoId: widget.materialPoId,
      );

      if (response != null && response.status == 1) {
        setState(() {
          _poDetail = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response?.message ?? 'Failed to load PO details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'delivered':
        return Colors.blue;
      case 'open':
        return Colors.blue;
      case 'closed':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day} ${months[date.month - 1]}, ${date.year} ${hour}:${date.minute.toString().padLeft(2, '0')} ${ampm}';
    } catch (e) {
      return dateString;
    }
  }

  String _getTotalOrderedQuantity(int materialId) {
    // Find the pending item with the same material ID and get its ordered quantity
    final pendingItem = _poDetail!.pendingItems.firstWhere(
      (item) => item.materialId == materialId,
      orElse: () =>
          _poDetail!.pendingItems.first, // Fallback to first item if not found
    );
    return pendingItem.quantityForDelivery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _poDetail?.purchaseOrderId ?? 'PO Details',
        showDrawer: false,
        showBackButton: true,
      ),

      body: GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _poDetail == null
            ? _buildEmptyState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Error Loading PO Details',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          CustomButton(text: 'Retry', onPressed: _loadPODetail),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No PO Details Found',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The purchase order details could not be loaded.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          if (_poDetail != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceColor),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_poDetail!.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _poDetail!.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(_poDetail!.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 10),
          _buildPurchaseOrderInfoSection(),
          SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              setState(() {
                _isExpandedPayments = !_isExpandedPayments;
              });
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADVANCE PAYMENT',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${_poDetail!.poPayment.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        _isExpandedPayments
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3),

          _buildAdvancePaymentSection(),

          GestureDetector(
            onTap: () async {
              if (_poDetail != null) {
                final result = await NavigationUtils.push(
                  context,
                  RecordAdvanceScreen(poDetail: _poDetail!),
                );
                if (result == true) {
                  _loadPODetail();
                }
              }
            },
            child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: AppColors.primary),
                  SizedBox(width: 5),
                  Text(
                    'Add Advance Payment',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 10),
          if (_poDetail!.pendingItems.isNotEmpty)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surfaceColor),
                  child: Text(
                    'Pending Items',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                SizedBox(height: 3),

                _buildPendingItemsSection(),
                SizedBox(height: 3),
                _buildReceivedQuantitySection(),
                SizedBox(height: 10),
              ],
            ),

          if (_poDetail!.deliveredItems.isNotEmpty)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surfaceColor),
                  child: Text(
                    'Delivered Items',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                SizedBox(height: 3),

                _buildDeliveredItemsSection(),
                SizedBox(height: 10),
              ],
            ),

          if (_poDetail!.grn.isNotEmpty) ...[
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surfaceColor),
                  child: Text(
                    'Linked GRN',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                SizedBox(height: 3),
                _buildLinkedGRNSection(),
                SizedBox(height: 20,)
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseOrderInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceColor),
          child: Text(
            'DETAILS',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.darkBorder,
            ),
          ),
        ),
        SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      'Created By',
                      '${_formatDateTime(_poDetail!.createdAt)}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Expected on',
                      _formatDate(_poDetail!.expectedDeliveryDate ?? ''),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      'Site Name',
                      _poDetail!.site.name ?? 'N/A',
                    ),
                  ),
                  Expanded(child: _buildDetailRow('Site POC', '-')),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow('Vendor', _poDetail!.vendorName),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Vendor Contact',
                      _poDetail!.vendorPhoneNo,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              _buildDetailRow('Office POC', '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancePaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExpandedPayments) ...[
          ..._poDetail!.poPayment.map(
            (payment) => _buildAdvancePaymentItem(payment),
          ),
          SizedBox(height: 3),
        ],
      ],
    );
  }

  Widget _buildDeliveredItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._poDetail!.deliveredItems
            .map((item) => _buildDeliveredItemCard(item))
            .toList(),
      ],
    );
  }

  Widget _buildPendingItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._poDetail!.pendingItems
            .map((item) => _buildPendingItemCard(item))
            .toList(),
      ],
    );
  }

  Widget _buildLinkedGRNSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [..._poDetail!.grn.map((grn) => _buildGRNLink(grn)).toList()],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: 2),
        Container(
          width: 150,
          child: Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancePaymentItem(POPayment payment) {
    return GestureDetector(
      onTap: () {
        NavigationUtils.push(
          context,
          PaymentDetailScreen(
            payment: payment,
            poDetail: _poDetail,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.access_time, color: Colors.white, size: 17),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.advanceId,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Paid By Company',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatDate(payment.paymentDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${payment.paymentAmount}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.keyboard_arrow_right, color: Colors.grey[600]),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Divider(height: 1.5),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveredItemCard(DeliveredItem item) {
    final material = item.material;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.name ?? 'Unknown Material',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          _buildItemDetail('Specification', material.specification ?? 'N/A'),
          _buildItemDetail('Brand', material.brandName ?? 'N/A'),
          _buildItemDetail(
            'Ordered Qty',
            '${_getTotalOrderedQuantity(material.id)} ${material.unitOfMeasurement ?? 'nos'}',
          ),
          _buildItemDetail(
            'Received Qty',
            '${item.quantity} ${material.unitOfMeasurement ?? 'nos'}',
          ),
          if (item.user != null)
            _buildItemDetail(
              'Received by',
              '${item.user!.firstName} ${item.user!.lastName} | ${_formatDateTime(item.createdAt)}',
            ),
          SizedBox(height: 5),
          Divider(height: 1.5),
        ],
      ),
    );
  }

  Widget _buildPendingItemCard(PendingItem item) {
    final material = item.material;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.name ?? 'Unknown Material',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          Text(
            material.specification ?? '-',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Brand: ${material.brandName ?? '-'}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ordered Qty:  ${item.quantityForDelivery} ${material.unitOfMeasurement ?? 'nos'}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Pending Qty:  ${item.pendingQuantity} ${material.unitOfMeasurement ?? 'nos'}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedQuantitySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECEIVED QUANTITY',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),

          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _receivedQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Please Enter Quantity',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                _poDetail!.pendingItems.isNotEmpty
                    ? _poDetail!.pendingItems.first.material.unitOfMeasurement
                    : 'nos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Add to Stock',
              onPressed: () async {
                if (_receivedQuantityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter quantity'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: EdgeInsets.all(16),
                    ),
                  );
                  return;
                }

                final quantity = int.tryParse(_receivedQuantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: EdgeInsets.all(16),
                    ),
                  );
                  return;
                }

                // Navigate to GRN screen
                final result = await NavigationUtils.push(
                  context,
                  RecordGrnScreen(
                    poDetail: _poDetail!,
                    pendingItem: _poDetail!.pendingItems.first,
                    receivedQuantity: _receivedQuantityController.text,
                  ),
                );

                if (result == true) {
                  // Clear the quantity field after successful GRN creation
                  _receivedQuantityController.clear();
                  // Refresh PO details
                  _loadPODetail();
                }
              },
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGRNLink(GRN grn) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          // Navigate to GRN details screen
          print('Navigating to GRN detail screen with ID: ${grn.id}');
          NavigationUtils.push(context, GrnDetailScreen(grnId: grn.id));
        },
        child: Text(
          grn.grnNumber,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
