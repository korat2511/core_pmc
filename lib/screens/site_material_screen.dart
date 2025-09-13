import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../models/material_model.dart';
import '../models/po_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_search_bar.dart';
import 'add_material_screen.dart';
import 'create_po_screen.dart';
import 'po_detail_screen.dart';
import 'material_details_screen.dart';

class SiteMaterialScreen extends StatefulWidget {
  final SiteModel site;

  const SiteMaterialScreen({super.key, required this.site});

  @override
  State<SiteMaterialScreen> createState() => _SiteMaterialScreenState();
}

class _SiteMaterialScreenState extends State<SiteMaterialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Materials data
  List<MaterialModel> _materials = [];
  List<MaterialModel> _filteredMaterials = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  final _searchController = TextEditingController();

  // PO Orders data
  List<POModel> _poOrders = [];
  List<POModel> _filteredPOOrders = [];
  bool _isLoadingPO = false;
  bool _isRefreshingPO = false;
  final _poSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    // Load materials when inventory tab is selected
    _loadMaterials();
    // Load PO orders when PO tab is selected
    _loadPOOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _poSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getMaterials(page: 1);

      if (response != null && response.status == 1) {
        setState(() {
          _materials = response.data;
          _filteredMaterials = response.data;
        });
      } else {
        // Handle error silently for now
        setState(() {
          _materials = [];
          _filteredMaterials = [];
        });
      }
    } catch (e) {
      setState(() {
        _materials = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMaterials() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadMaterials();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _filterMaterials(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredMaterials = _materials;
        } else {
          _filteredMaterials = _materials.where((material) {
            return material.name.toLowerCase().contains(query.toLowerCase()) ||
                material.sku.toLowerCase().contains(query.toLowerCase()) ||
                material.brandName?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ==
                    true;
          }).toList();
        }
      });
    }
  }

  Future<void> _loadPOOrders() async {
    setState(() {
      _isLoadingPO = true;
    });

    try {
      final response = await ApiService.getPOOrders(
        siteId: widget.site.id,
        page: 1,
      );

      if (response != null && response.status == 1) {
        setState(() {
          _poOrders = response.data ?? [];
          _filteredPOOrders = response.data ?? [];
        });
      } else {
        setState(() {
          _poOrders = [];
          _filteredPOOrders = [];
        });
      }
    } catch (e) {
      setState(() {
        _poOrders = [];
        _filteredPOOrders = [];
      });
    } finally {
      setState(() {
        _isLoadingPO = false;
      });
    }
  }

  Future<void> _refreshPOOrders() async {
    setState(() {
      _isRefreshingPO = true;
    });

    await _loadPOOrders();

    setState(() {
      _isRefreshingPO = false;
    });
  }

  void _filterPOOrders(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredPOOrders = _poOrders;
        } else {
          _filteredPOOrders = _poOrders.where((po) {
            return po.purchaseOrderId.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                po.vendorName.toLowerCase().contains(query.toLowerCase()) ||
                po.status.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                NavigationUtils.push(
                  context,
                  CreatePOScreen(site: widget.site),
                );
              },
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add),
              label: Text('Add PO'),
            )
          : _currentTabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                NavigationUtils.push(
                  context,
                  AddMaterialScreen(site: widget.site),
                );
              },
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add),
              label: Text('Add Material'),
            )
          : null,
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3,
              labelStyle: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart, size: 20),
                      SizedBox(width: 8),
                      Text('PO & Delivery'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 20),
                      SizedBox(width: 8),
                      Text('Inventory'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // PO & Delivery Tab
                _buildPODeliveryTab(),

                // Inventory Tab
                _buildInventoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPODeliveryTab() {
    if (_isLoadingPO) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredPOOrders.isEmpty) {
      return Container(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 64,
                  tablet: 80,
                  desktop: 96,
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
                'You do not have any Purchase order',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Create your first purchase order to get started',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  NavigationUtils.push(
                    context,
                    CreatePOScreen(site: widget.site),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Create Purchase Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Column(
        children: [
          // Search Bar
          SizedBox(height: 8),
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: CustomSearchBar(
              hintText: 'Search PO orders...',
              onChanged: _filterPOOrders,
              controller: _poSearchController,
            ),
          ),

          // PO Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPOOrders,
              child: ListView.builder(
                padding: ResponsiveUtils.responsivePadding(context),
                itemCount: _filteredPOOrders.length,
                itemBuilder: (context, index) {
                  final poOrder = _filteredPOOrders[index];
                  return _buildPOCard(poOrder);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredMaterials.isEmpty) {
      return Container(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 64,
                  tablet: 80,
                  desktop: 96,
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
                'Inventory is empty',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Add materials to your inventory to track stock levels',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  NavigationUtils.push(
                    context,
                    AddMaterialScreen(site: widget.site),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Add to Inventory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Column(
        children: [
          // Search Bar
          SizedBox(height: 8),
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: CustomSearchBar(
              hintText: 'Search materials...',
              onChanged: _filterMaterials,
              controller: _searchController,
            ),
          ),

          // Materials List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMaterials,
              child: ListView.builder(
                padding: ResponsiveUtils.responsivePadding(context),
                itemCount: _filteredMaterials.length,
                itemBuilder: (context, index) {
                  final material = _filteredMaterials[index];
                  return _buildMaterialCard(material);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(MaterialModel material) {
    return GestureDetector(
      onTap: () {
        NavigationUtils.push(
          context,
          MaterialDetailsScreen(
            materialId: material.id,
            materialName: material.name,
            siteName: widget.site.name,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material.name,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (material.specification != null) ...[
              SizedBox(height: 2,),
              Text(
                "${material.specification}",
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
            if (material.brandName != null) ...[
              SizedBox(height: 2,),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Brand: ",
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: "${material.brandName}",
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                    TextSpan(
                      text: " | Item Code: ",
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: "${material.sku}",
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ...[
            SizedBox(height: 2,),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "UOM: ",
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: "${material.unitOfMeasurement}",
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
            if (material.currentStock != null) ...[
              SizedBox(height: 2,),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "In stock: ",
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: "${material.currentStock}",
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 2,),
            Divider(),
            SizedBox(height: 10,)

          ],
        ),
      ),
    );
  }

  Widget _buildPOCard(POModel poOrder) {
    Color _getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'open':
          return Colors.blue;
        case 'closed':
          return Colors.green;
        case 'ordered':
          return Colors.grey;
        case 'delivered':
          return Colors.lightGreen;
        case 'pending':
          return Colors.orange;
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
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

    return GestureDetector(
      onTap: () {
        NavigationUtils.push(
          context,
          PODetailScreen(
            materialPoId: poOrder.id,
            poNumber: poOrder.purchaseOrderId,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PO Number at the top
              Text(
                poOrder.purchaseOrderId,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 18,
                ),
              ),

              SizedBox(height: 12),

              // Status Badges
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(poOrder.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      poOrder.status.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ORDERED',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Details Section with Label-Value pairs
              _buildDetailRow(
                'Created By',
                'Rutvik | ${_formatDateTime(poOrder.createdAt)}',
              ),
              SizedBox(height: 8),
              _buildDetailRow('Vendor', poOrder.vendorName),
              SizedBox(height: 8),
              _buildDetailRow('Material', 'Asian Paint'),
              // Placeholder - you'll need to add material info to your model
              SizedBox(height: 8),
              _buildDetailRowWithIcon(
                'Expected delivery',
                _formatDate(poOrder.expectedDeliveryDate),
                Icons.local_shipping,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithIcon(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
