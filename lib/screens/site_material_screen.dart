import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import 'add_material_screen.dart';
import 'create_po_screen.dart';

class SiteMaterialScreen extends StatefulWidget {
  final SiteModel site;

  const SiteMaterialScreen({
    super.key,
    required this.site,
  });

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
                   material.brandName?.toLowerCase().contains(query.toLowerCase()) == true;
          }).toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

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
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material.name,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'SKU: ${material.sku}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Category ID: ${material.categoryId}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'UOM: ${material.unitOfMeasurement}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Price: ₹ ${material.unitPrice}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),

            if (material.brandName != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Brand: ${material.brandName}',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
