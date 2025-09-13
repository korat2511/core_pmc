import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/po_detail_model.dart';
import '../widgets/custom_app_bar.dart';

class PaymentDetailScreen extends StatefulWidget {
  final POPayment payment;
  final PODetailModel? poDetail;

  const PaymentDetailScreen({
    super.key,
    required this.payment,
    this.poDetail,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Payment Details',
        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Status Badge
                  _buildStatusSection(),
                  SizedBox(height: 10),

                  // Payment Information
                  _buildPaymentInfoSection(),
                  SizedBox(height: 10),

                  // Payment Details
                  _buildPaymentDetailsSection(),
                  SizedBox(height: 10),

                  // Attachments/Documents Section
                  _buildDocumentsSection(),
                  SizedBox(height: 10),

                
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceColor),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'PAID',
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceColor),
          child: Text(
            'PAYMENT INFORMATION',
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
                      'Payment ID',
                      widget.payment.advanceId,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Payment Date',
                      _formatDate(widget.payment.paymentDate),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      'Payment Mode',
                      widget.payment.paymentMode.toUpperCase().replaceAll('_', ' '),
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Amount',
                      '₹${widget.payment.paymentAmount}',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              if (widget.payment.transactionId != null && widget.payment.transactionId!.isNotEmpty)
                _buildDetailRow(
                  'Transaction ID',
                  widget.payment.transactionId!,
                ),
              if (widget.payment.remark != null && widget.payment.remark!.isNotEmpty) ...[
                SizedBox(height: 15),
                _buildDetailRow(
                  'Remarks',
                  widget.payment.remark!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceColor),
          child: Text(
            'PAYMENT DETAILS',
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
                      '${widget.payment.user.firstName} ${widget.payment.user.lastName}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Created On',
                      _formatDateTime(widget.payment.createdAt),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              if (widget.poDetail != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        'PO Number',
                        widget.poDetail!.purchaseOrderId,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailRow(
                        'Paid To',
                        widget.poDetail!.vendorName,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                _buildDetailRow(
                  'Site',
                  widget.poDetail!.site.name,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ATTACHMENTS',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: AppColors.darkBorder,
                ),
              ),
              Text(
                '${widget.payment.poPaymentDocument.length}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceColor),
          child: widget.payment.poPaymentDocument.isEmpty
              ? Container(

                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_file_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No attachments available',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
            padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: widget.payment.poPaymentDocument.length,
                  itemBuilder: (context, index) {
                    final document = widget.payment.poPaymentDocument[index];
                    return GestureDetector(
                      onTap: () => _showDocumentFullScreen(document, index),
                      child: Image.network(
                        document['document_url'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey[400], size: 24),
                                SizedBox(height: 4),
                                Text(
                                  'Failed to load',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
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

  void _showDocumentFullScreen(dynamic document, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attachment ${index + 1}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              // Image
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      document['document_url'] ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load document',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Footer with description
              if (document['description'] != null && document['description'].isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          document['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
}
