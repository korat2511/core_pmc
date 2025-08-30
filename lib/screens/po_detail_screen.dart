import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/po_detail_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      orElse: () => _poDetail!.pendingItems.first, // Fallback to first item if not found
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
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
          ElevatedButton(
            onPressed: _loadPODetail,
            child: Text('Retry'),
          ),
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
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          if (_poDetail != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_poDetail!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
            SizedBox(height: 10),
          ],

          // Purchase Order Info Section
          _buildPurchaseOrderInfoSection(),

          SizedBox(height: 8),

          // Advance Payment Section
          _buildAdvancePaymentSection(),

          SizedBox(height: 8),

          // Delivered Items Section
          if (_poDetail!.deliveredItems.isNotEmpty)
            _buildDeliveredItemsSection(),



          // Pending Items Section
          if (_poDetail!.pendingItems.isNotEmpty)
            _buildPendingItemsSection(),



          // Linked GRN Section
          if (_poDetail!.grn.isNotEmpty) ...[
            _buildLinkedGRNSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseOrderInfoSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase Order Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Created By', 'Rutvik Korat | ${_formatDateTime(_poDetail!.createdAt)}'),
            _buildInfoRow('Expected on', _formatDate(_poDetail!.expectedDeliveryDate ?? '')),
            _buildInfoRow('Site Name', _poDetail!.site.name ?? 'N/A'),
            _buildInfoRow('Site POC', '-'),
            _buildInfoRow('Vendor', _poDetail!.vendorName ?? 'N/A'),
            _buildInfoRow('Vendor Contact', _poDetail!.vendorPhoneNo ?? 'N/A'),
            _buildInfoRow('Office POC', '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancePaymentSection() {
    double totalAdvance = _poDetail!.poPayment.fold(0.0, (sum, payment) => 
      sum + (double.tryParse(payment.paymentAmount) ?? 0.0));

    return Card(
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
                  'ADVANCE PAYMENT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₹${totalAdvance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_up, color: Colors.grey[600]),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_poDetail!.poPayment.isNotEmpty) ...[
              ..._poDetail!.poPayment.map((payment) => _buildAdvancePaymentItem(payment)).toList(),
            ] else ...[
              Text(
                'No advance payments',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await NavigationUtils.push(
                    context,
                    RecordAdvanceScreen(poDetail: _poDetail!),
                  );
                  if (result == true) {
                    // Refresh PO details after successful payment
                    _loadPODetail();
                  }
                },
                icon: Icon(Icons.add, size: 18),
                label: Text('Add Advance Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveredItemsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivered Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            ..._poDetail!.deliveredItems.map((item) => _buildDeliveredItemCard(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItemsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 6),
            ..._poDetail!.pendingItems.map((item) => _buildPendingItemCard(item)).toList(),

            _buildReceivedQuantitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedGRNSection() {
    return Container(
      width: double.infinity,
      child: Card(

        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Linked GRN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              ..._poDetail!.grn.map((grn) => _buildGRNLink(grn)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancePaymentItem(POPayment payment) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.advanceId,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Paid By Company',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatDate(payment.paymentDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${payment.paymentAmount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Icon(Icons.keyboard_arrow_right, color: Colors.grey[600]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredItemCard(DeliveredItem item) {
    final material = item.material;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
          _buildItemDetail('Ordered Qty', '${_getTotalOrderedQuantity(material.id)} ${material.unitOfMeasurement ?? 'nos'}'),
          _buildItemDetail('Received Qty', '${item.quantity} ${material.unitOfMeasurement ?? 'nos'}'),
          if (item.user != null)
            _buildItemDetail('Received by', '${item.user!.firstName} ${item.user!.lastName} | ${_formatDateTime(item.createdAt)}'),
        ],
      ),
    );
  }

  Widget _buildPendingItemCard(PendingItem item) {
    final material = item.material;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
          _buildItemDetail('Ordered Qty', '${item.quantityForDelivery} ${material.unitOfMeasurement ?? 'nos'}'),
          _buildItemDetail('Pending Qty', '${item.pendingQuantity} ${material.unitOfMeasurement ?? 'nos'}'),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECEIVED QUANTITY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                _poDetail!.pendingItems.isNotEmpty 
                    ? _poDetail!.pendingItems.first.material.unitOfMeasurement ?? 'nos'
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
            child: ElevatedButton(
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
              child: Text('Add to Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
          // TODO: Navigate to GRN details
        },
        child: Text(
          grn.grnNumber ?? 'Unknown GRN',
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
