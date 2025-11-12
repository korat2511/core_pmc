import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/grn_detail_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import 'record_advance_screen.dart';

class GrnDetailScreen extends StatefulWidget {
  final int grnId;

  const GrnDetailScreen({super.key, required this.grnId});

  @override
  State<GrnDetailScreen> createState() => _GrnDetailScreenState();
}

class _GrnDetailScreenState extends State<GrnDetailScreen> {
  GrnDetailModel? _grnDetail;
  bool _isLoading = true;
  bool _isExpandedMaterials = false;
  bool _isExpandedPhotos = false;

  @override
  void initState() {
    super.initState();
    _loadGrnDetail();
  }

  Future<void> _loadGrnDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getGrnDetail(grnId: widget.grnId);

      if (response != null && response.status == 1) {
        setState(() {
          _grnDetail = response.data;
        });
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to load GRN details',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error loading GRN details: ${e.toString()}',
      );
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
        title: _grnDetail?.grnNumber ?? 'GRN Details',
        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _grnDetail == null
          ? Center(
              child: Text(
                'No GRN details found',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsSection(),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      if (_grnDetail != null) {
                        final result = await NavigationUtils.push(
                          context,
                          RecordAdvanceScreen(grnDetail: _grnDetail!),
                        );
                        if (result == true) {
                          // Refresh GRN details after successful payment
                          _loadGrnDetail();
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpandedMaterials = !_isExpandedMaterials;
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
                            'RECEIVED MATERIALS',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_grnDetail!.grnDetail.length}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                _isExpandedMaterials
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

                  _buildReceivedMaterialsSection(),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpandedPhotos = !_isExpandedPhotos;
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
                            'PHOTOS',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_grnDetail!.grnDocument.length}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                _isExpandedPhotos
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

                  _buildPhotosSection(),
                  // SizedBox(height: 16),
                  //
                  // // Linked GRNs Section
                  // if (_grnDetail!.grnsLinkedToSamePo.isNotEmpty) ...[
                  //   _buildLinkedGrnsSection(),
                  //   SizedBox(height: 16),
                  // ],
                ],
              ),
            ),
    );
  }

  Widget _buildDetailsSection() {
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
                    child: _buildDetailRow('Created By', _getCreatedByText()),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Received On',
                      _formatDate(_grnDetail!.grnDate),
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
                      _grnDetail!.siteName ?? '-',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Vendor',
                      _grnDetail!.vendor?.name ?? '-',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      'Invoice Total Amount',
                      '₹${_calculateInvoiceTotal()}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      'Invoice Number',
                      _grnDetail!.deliveryChallanNumber,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              _buildDetailRow('Total Cost', '₹${_calculateTotalCost()}'),
            ],
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


  Widget _buildReceivedMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (_isExpandedMaterials) ...[
          ..._grnDetail!.grnDetail.map(
            (material) => _buildMaterialCard(material),
          ),
        ],
      ],
    );
  }

  Widget _buildMaterialCard(GrnDetailItem material) {
    return Container(

      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,


      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.material?.name ?? 'Unknown Material',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          Text(
            material.material?.specification ?? '-',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Brand: ${material.material?.brandName ?? '-'}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Received Qty: ${material.quantity} ${material.material?.unitOfMeasurement ?? ''}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (_isExpandedPhotos) ...[

          if (_grnDetail!.grnDocument.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],

              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No photos available',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              color: Colors.white,
              child: GridView.builder(
               padding: EdgeInsets.all(10),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: _grnDetail!.grnDocument.length,
                itemBuilder: (context, index) {
                  final document = _grnDetail!.grnDocument[index];
                  return GestureDetector(
                    onTap: () => _showImageFullScreen(document, index),
                    child: Image.network(
                      document.documentUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Failed to load',
                                style: TextStyle(
                                  fontSize: 12,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor,
                              ),
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
      ],
    );
  }


  void _showImageFullScreen(GrnDocument document, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageFullScreenViewer(
          documents: _grnDetail!.grnDocument,
          initialIndex: index,
        ),
      ),
    );
  }

  String _getCreatedByText() {
    if (_grnDetail!.createdAt != null) {
      final date = DateTime.parse(_grnDetail!.createdAt!);
      return 'User | ${_formatDateTime(date)}';
    }
    return 'Unknown';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM, yyyy hh:mm a').format(date);
  }

  String _calculateInvoiceTotal() {
    // Calculate total from materials
    double total = 0;
    for (final material in _grnDetail!.grnDetail) {
      final quantity = material.quantity;
      final unitPrice =
          double.tryParse(material.material?.unitPrice ?? '0') ?? 0;
      total += quantity * unitPrice;
    }
    return total.toStringAsFixed(2);
  }

  String _calculateTotalCost() {
    // Same as invoice total for now
    return _calculateInvoiceTotal();
  }
}

class _ImageFullScreenViewer extends StatefulWidget {
  final List<GrnDocument> documents;
  final int initialIndex;

  const _ImageFullScreenViewer({
    required this.documents,
    required this.initialIndex,
  });

  @override
  State<_ImageFullScreenViewer> createState() => _ImageFullScreenViewerState();
}

class _ImageFullScreenViewerState extends State<_ImageFullScreenViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: '${_currentIndex + 1} of ${widget.documents.length}',
        showDrawer: false,
        showBackButton: true,
      ),

      body: Column(
        children: [
          // Image viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.documents.length,
              itemBuilder: (context, index) {
                final document = widget.documents[index];
                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      document.documentUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // Image information below
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Description: ${widget.documents[_currentIndex].description}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Uploaded: ${_formatUploadDate(widget.documents[_currentIndex].createdAt)}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                SizedBox(height: 15,)
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUploadDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
