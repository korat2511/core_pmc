import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/qc_category_model.dart';
import '../models/qc_point_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dismiss_keyboard.dart';

class QcPointsScreen extends StatefulWidget {
  final SiteModel site;
  final QcCategoryModel category;

  const QcPointsScreen({
    super.key,
    required this.site,
    required this.category,
  });

  @override
  State<QcPointsScreen> createState() => _QcPointsScreenState();
}

class _QcPointsScreenState extends State<QcPointsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QcPointModel> _prePoints = [];
  List<QcPointModel> _duringPoints = [];
  List<QcPointModel> _afterPoints = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _editPointController = TextEditingController();
  final TextEditingController _addPointController = TextEditingController();
  String _selectedType = 'pre';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQcPoints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editPointController.dispose();
    _addPointController.dispose();
    super.dispose();
  }

  Future<void> _loadQcPoints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      // Load points for all three types
      final preResponse = await ApiService.getQcPoints(
        apiToken: apiToken,
        type: 'pre',
        categoryId: widget.category.id,
      );

      final duringResponse = await ApiService.getQcPoints(
        apiToken: apiToken,
        type: 'during',
        categoryId: widget.category.id,
      );

      final afterResponse = await ApiService.getQcPoints(
        apiToken: apiToken,
        type: 'after',
        categoryId: widget.category.id,
      );

      if (mounted) {
        setState(() {
          _prePoints = preResponse.isSuccess ? preResponse.points : [];
          _duringPoints = duringResponse.isSuccess ? duringResponse.points : [];
          _afterPoints = afterResponse.isSuccess ? afterResponse.points : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load QC points: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showEditPointModal(QcPointModel point) {
    _editPointController.text = point.point;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildEditPointModal(point),
      ),
    );
  }

  Widget _buildEditPointModal(QcPointModel point) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: AppColors.primaryColor,
                  size: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 16,
                    desktop: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit QC Point',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.category.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Form
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              children: [
                CustomTextField(
                  controller: _editPointController,
                  label: 'QC Point',
                  hintText: 'Enter QC point description',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updatePoint(point),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Update QC Point',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePoint(QcPointModel point) async {
    final pointText = _editPointController.text.trim();
    
    if (pointText.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Please enter a QC point description',
      );
      return;
    }

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final response = await ApiService.updateQcPoint(
        apiToken: apiToken,
        type: point.type,
        point: pointText,
        pointId: point.id,
        categoryId: point.categoryId,
      );

      if (response.isSuccess) {
        Navigator.of(context).pop();
        _loadQcPoints(); // Refresh the data
        SnackBarUtils.showSuccess(
          context,
          message: 'QC Point updated successfully',
        );
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message,
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to update QC point: $e',
      );
    }
  }

  void _showDeleteConfirmation(QcPointModel point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete QC Point',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this QC point?\n\n"${point.point}"\n\nThis action cannot be undone.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePoint(point);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: AppColors.textWhite,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePoint(QcPointModel point) async {
    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final response = await ApiService.deleteQcPoint(
        apiToken: apiToken,
        pointId: point.id,
      );

      if (response.isSuccess) {
        _loadQcPoints(); // Refresh the data
        SnackBarUtils.showSuccess(
          context,
          message: 'QC Point deleted successfully',
        );
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message,
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to delete QC point: $e',
      );
    }
  }

  void _showAddPointModal() {
    _addPointController.clear();
    _selectedType = 'pre';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildAddPointModal(),
      ),
    );
  }

  Widget _buildAddPointModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primaryColor,
                  size: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 16,
                    desktop: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New QC Point',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.category.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Form
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              children: [
                // Type Selection
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                    vertical: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                                                                                Expanded(
                             child: GestureDetector(
                               onTap: () => setModalState(() => _selectedType = 'pre'),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedType == 'pre' 
                                      ? AppColors.successColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedType == 'pre' 
                                        ? AppColors.successColor
                                        : AppColors.borderColor,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Pre',
                                    style: TextStyle(
                                      color: _selectedType == 'pre' 
                                          ? AppColors.successColor
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => _selectedType = 'during'),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedType == 'during' 
                                      ? AppColors.warningColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedType == 'during' 
                                        ? AppColors.warningColor
                                        : AppColors.borderColor,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'During',
                                    style: TextStyle(
                                      color: _selectedType == 'during' 
                                          ? AppColors.warningColor
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => _selectedType = 'after'),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedType == 'after' 
                                      ? AppColors.errorColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedType == 'after' 
                                        ? AppColors.errorColor
                                        : AppColors.borderColor,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'After',
                                    style: TextStyle(
                                      color: _selectedType == 'after' 
                                          ? AppColors.errorColor
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 16,
                    tablet: 20,
                    desktop: 24,
                  ),
                ),
                
                // Point Description
                CustomTextField(
                  controller: _addPointController,
                  label: 'QC Point Description',
                  hintText: 'Enter QC point description',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addPoint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Add QC Point',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Future<void> _addPoint() async {
    final pointText = _addPointController.text.trim();
    
    if (pointText.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Please enter a QC point description',
      );
      return;
    }

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final response = await ApiService.storeQcPoint(
        apiToken: apiToken,
        type: _selectedType,
        point: pointText,
        categoryId: widget.category.id,
      );

      if (response.isSuccess) {
        Navigator.of(context).pop();
        _loadQcPoints(); // Refresh the data
        SnackBarUtils.showSuccess(
          context,
          message: 'QC Point added successfully',
        );
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message,
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to add QC point: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.category.name,
        showDrawer: false,
        showBackButton: true,
      ),
      body: DismissKeyboard(
        child: Column(
          children: [
            // Tab Bar
            Container(
              color: AppColors.surfaceColor,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryColor,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 16),
                        SizedBox(width: 4),
                        Text('Pre'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause, size: 16),
                        SizedBox(width: 4),
                        Text('During'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop, size: 16),
                        SizedBox(width: 4),
                        Text('After'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
SizedBox(height: 10,),
            // Tab Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 60,
                                  tablet: 80,
                                  desktop: 100,
                                ),
                                color: AppColors.errorColor,
                              ),
                              SizedBox(
                                height: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  desktop: 24,
                                ),
                              ),
                              Text(
                                _errorMessage,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 16,
                                    tablet: 18,
                                    desktop: 20,
                                  ),
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  desktop: 24,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _loadQcPoints,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPointsList(_prePoints, 'Pre'),
                            _buildPointsList(_duringPoints, 'During'),
                            _buildPointsList(_afterPoints, 'After'),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPointModal,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textWhite,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPointsList(List<QcPointModel> points, String type) {
    return RefreshIndicator(
      onRefresh: _loadQcPoints,
      color: AppColors.primaryColor,
      child: points.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'Pre' ? Icons.play_arrow : type == 'During' ? Icons.pause : Icons.stop,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 60,
                      tablet: 80,
                      desktop: 100,
                    ),
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),
                  Text(
                    'No $type points available',
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: ResponsiveUtils.horizontalPadding(context),
              itemCount: points.length,
              itemBuilder: (context, index) {
                final point = points[index];
                return _buildPointCard(point, index + 1);
              },
            ),
    );
  }

  Widget _buildPointCard(QcPointModel point, int index) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textLight.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number Badge
            Container(
              width: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 32,
                tablet: 36,
                desktop: 40,
              ),
              height: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 32,
                tablet: 36,
                desktop: 40,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(
              width: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),

            // Point Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.point,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 4,
                      tablet: 6,
                      desktop: 8,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 6,
                            tablet: 8,
                            desktop: 10,
                          ),
                          vertical: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 2,
                            tablet: 4,
                            desktop: 6,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(point.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 4,
                              tablet: 6,
                              desktop: 8,
                            ),
                          ),
                        ),
                        child: Text(
                          point.type.toUpperCase(),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 10,
                              tablet: 12,
                              desktop: 14,
                            ),
                            color: _getTypeColor(point.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),
                      Text(
                        'ID: ${point.id}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 10,
                            tablet: 12,
                            desktop: 14,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Column(
              children: [
                // Edit Button
                GestureDetector(
                  onTap: () => _showEditPointModal(point),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
                
                // Delete Button
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(point),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.errorColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pre':
        return AppColors.successColor;
      case 'during':
        return AppColors.warningColor;
      case 'after':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }
}
