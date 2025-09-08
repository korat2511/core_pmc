import 'package:core_pmc/core/utils/navigation_utils.dart';
import 'package:core_pmc/models/site_model.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/element_model.dart';
import '../models/stone_quantity_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import 'add_stone_quantity_screen.dart';

class StoneQuantityDetailScreen extends StatefulWidget {
  final ElementModel element;
  final SiteModel site;

  const StoneQuantityDetailScreen({
    super.key,
    required this.element,
    required this.site,
  });

  @override
  State<StoneQuantityDetailScreen> createState() => _StoneQuantityDetailScreenState();
}

class _StoneQuantityDetailScreenState extends State<StoneQuantityDetailScreen> {
  List<StoneQuantityModel> _stoneQuantities = [];
  bool _isLoading = false;
  double _totalSum = 0.0;
  final TransformationController _transformationController = TransformationController();
  double _tableWidth = 0.0;
  double _screenWidth = 0.0;
  double _fitToScreenScale = 1.0;
  bool _initialZoomSet = false;

  @override
  void initState() {
    super.initState();
    _loadStoneQuantities();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadStoneQuantities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getStoneQuantity(
          apiToken: token,
          siteElementId: widget.element.id,
          siteId: widget.site.id,
        );

        if (response != null && response['status'] == 1) {
          final List<dynamic> data = response['data'] ?? [];
          setState(() {
            _stoneQuantities = data.map((json) => StoneQuantityModel.fromJson(json)).toList();
            _calculateTotalSum();
          });
          // Set initial zoom after data loads
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setInitialZoom();
          });
        } else {
          SnackBarUtils.showError(
            context,
            message: response?['message'] ?? 'Failed to load stone quantities',
          );
        }
      } else {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTotalSum() {
    _totalSum = _stoneQuantities.fold(0.0, (sum, item) => sum + item.total);
  }

  void _calculateTableWidth() {
    // Calculate total table width based on column widths
    _tableWidth = 60 + 200 + 100 + 200 + 120 + 400 + 180 + 120 + 250 + 120; // Sum of all column widths
  }

  void _calculateFitToScreenScale() {
    if (_screenWidth > 0 && _tableWidth > 0) {
      _fitToScreenScale = _screenWidth / _tableWidth;
      // Ensure minimum scale is 0.3 to keep text readable
      _fitToScreenScale = _fitToScreenScale.clamp(0.3, 1.0);
    }
  }

  void _setInitialZoom() {
    if (!_initialZoomSet && _fitToScreenScale < 1.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialZoomSet) {
          _transformationController.value = Matrix4.identity()..scale(_fitToScreenScale);
          _initialZoomSet = true;
        }
      });
    }
  }

  void _zoomIn() {
    final Matrix4 matrix = _transformationController.value.clone();
    matrix.scale(1.2);
    _transformationController.value = matrix;
    _initialZoomSet = true; // Mark that user has interacted
  }

  void _zoomOut() {
    final Matrix4 matrix = _transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = currentScale * 0.8;
    
    // Don't allow zooming out beyond fit-to-screen scale
    if (newScale >= _fitToScreenScale) {
      matrix.scale(0.8);
      _transformationController.value = matrix;
      _initialZoomSet = true; // Mark that user has interacted
    }
  }

  void _resetZoom() {
    // Reset to fit-to-screen scale instead of 1.0
    _transformationController.value = Matrix4.identity()..scale(_fitToScreenScale);
    _initialZoomSet = true; // Mark as set since we're explicitly setting it
  }

  void _addStoneQuantity() {
NavigationUtils.push(
  context,
  AddStoneQuantityScreen(
    element: widget.element,
    site: widget.site,
  ),
).then((result) {
      // Reload data if a new stone quantity was added
      if (result == true) {
        _loadStoneQuantities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate screen width and table dimensions
    _screenWidth = MediaQuery.of(context).size.width;
    _calculateTableWidth();
    _calculateFitToScreenScale();
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Stone Quantity - ${widget.element.name}',
        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _stoneQuantities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No stone quantities found',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No stone quantity data available for ${widget.element.name}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Zoom instruction banner
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Table fits to screen by default. Pinch to zoom or use buttons.',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Interactive table
                    Expanded(
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: _fitToScreenScale,
                          maxScale: 3.0,
                          constrained: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTableHeader(),
                            _buildTableRows(),
                            _buildTableFooter(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add button
          FloatingActionButton(
            heroTag: "add_stone_quantity",
            onPressed: _addStoneQuantity,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(Icons.add, color: Colors.white),
          ),
          SizedBox(height: 8),
          // Zoom controls (only show if there's data)
          if (_stoneQuantities.isNotEmpty) ...[
            FloatingActionButton(
              heroTag: "zoom_in",
              mini: true,
              onPressed: _zoomIn,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.zoom_in, color: Colors.white),
            ),
            SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "zoom_out",
              mini: true,
              onPressed: _zoomOut,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.zoom_out, color: Colors.white),
            ),
            SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "reset_zoom",
              mini: true,
              onPressed: _resetZoom,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Headers Row
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderCell('S.NO.', width: 60),
                  _buildHeaderCell('LOCATION', width: 200),
                  _buildHeaderCell('CODE', width: 100),
                  _buildHeaderCell('STONE NAME', width: 200),
                  _buildHeaderCell('FLOOR AREA', width: 120),
                  _buildHeaderCell('SKIRTING', width: 400, isNestedHeader: true),
                  _buildHeaderCell('COUNTER TOP/ADDITIONAL', width: 180),
                  _buildHeaderCell('WALL', width: 120),
                  _buildHeaderCell('TOTAL AREA OF COUNTER TOP, SKIRTING & WALL', width: 250),
                  _buildHeaderCell('TOTAL', width: 120, isLastColumn: true),
                ],
              ),
            ),
          ),
          // Nested Skirting Headers Row
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 60 + 200 + 100 + 200 + 120), // Offset for preceding columns
                  _buildHeaderCell('LENGTH', width: 100, isNested: true),
                  _buildHeaderCell('HEIGHT', width: 100, isNested: true),
                  _buildHeaderCell('SUBTRACT-LENGTH', width: 100, isNested: true),
                  _buildHeaderCell('AREA', width: 100, isNested: true, isLastColumn: true),
                  // Empty space for remaining columns
                  SizedBox(width: 180 + 120 + 250 + 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required double width, bool isNestedHeader = false, bool isNested = false, bool isLastColumn = false}) {
    return Container(
      width: width,
      alignment: isNestedHeader ? Alignment.center : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: isLastColumn ? null : Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        text,
        style: isNested
            ? AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              )
            : AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        textAlign: isNestedHeader ? TextAlign.center : TextAlign.left,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableRows() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _stoneQuantities.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: index % 2 == 0 
                ? Theme.of(context).colorScheme.surface 
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDataCell((index + 1).toString(), width: 60),
                _buildDataCell(item.location.name, width: 200),
                _buildDataCell(item.code ?? '-', width: 100),
                _buildDataCell(item.stone.name, width: 200),
                _buildDataCell('${item.floorArea.toStringAsFixed(0)} SQ. FT.', width: 120),
                _buildDataCell(item.skirtingLength, width: 100),
                _buildDataCell(item.skirtingHeight, width: 100),
                _buildDataCell(item.skirtingSubtractLength, width: 100),
                _buildDataCell('${item.skirtingArea.toStringAsFixed(0)} SQ.FT.', width: 100),
                _buildDataCell('${item.counterTopAdditional.toStringAsFixed(0)} SQ. FT.', width: 180),
                _buildDataCell('${item.wallArea.toStringAsFixed(0)} SQ. FT.', width: 120),
                _buildDataCell('${item.totalCounterSkirtingWall.toStringAsFixed(0)} SQ.FT.', width: 250),
                _buildDataCell('${item.total.toStringAsFixed(0)} SQ. FT.', width: 120, isLastColumn: true),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataCell(String text, {required double width, bool isLastColumn = false}) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: isLastColumn ? null : Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableFooter() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 60 + 200 + 100 + 200 + 120 + 400 + 180 + 120 + 250 - 120), // Offset to align with TOTAL column
            _buildHeaderCell('TOTAL', width: 120),
            _buildHeaderCell('${_totalSum.toStringAsFixed(0)} SQ.FT.', width: 120, isLastColumn: true),
          ],
        ),
      ),
    );
  }
}
