import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/material_model.dart';
import '../models/po_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_search_bar.dart';
import 'add_material_screen.dart';
import 'create_po_screen.dart';
import 'po_detail_screen.dart';
import 'grn_detail_screen.dart';
import 'material_details_screen.dart';
import 'grn_material_selection_screen.dart';
import 'record_grn_screen.dart';

class SiteMaterialScreen extends StatefulWidget {
  final SiteModel site;

  const SiteMaterialScreen({super.key, required this.site});

  @override
  State<SiteMaterialScreen> createState() => _SiteMaterialScreenState();
}

class _SiteMaterialScreenState extends State<SiteMaterialScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _poGrnTabController;
  late TabController _inventoryTabController;
  int _currentMainTabIndex = 0;
  int _previousMainTabIndex = 0;
  int _previousPOGrnTabIndex = 0;
  int _previousInventoryTabIndex = 0;

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

  // GRN data
  List<dynamic> _grnOrders = [];
  List<dynamic> _filteredGrnOrders = [];
  bool _isLoadingGRN = false;
  bool _isRefreshingGRN = false;
  final _grnSearchController = TextEditingController();

  // Expanded state for PO and GRN cards
  Set<int> _expandedPOIds = {};
  Set<int> _expandedGrnIds = {};

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _poGrnTabController = TabController(length: 2, vsync: this);
    _inventoryTabController = TabController(length: 3, vsync: this);

    _mainTabController.addListener(() {
      if (_mainTabController.index != _previousMainTabIndex) {
        _previousMainTabIndex = _mainTabController.index;
        setState(() {
          _currentMainTabIndex = _mainTabController.index;
        });
        // Refresh data when switching main tabs
        if (_mainTabController.index == 0) {
          // PO & Delivery tab selected - refresh PO and GRN based on current sub-tab
          if (_poGrnTabController.index == 0) {
            _loadPOOrders();
          } else {
            _loadGrnOrders();
          }
        } else if (_mainTabController.index == 1) {
          // Inventory tab selected - refresh materials
          _loadMaterials();
        }
      }
    });

    _poGrnTabController.addListener(() {
      if (_poGrnTabController.index != _previousPOGrnTabIndex) {
        _previousPOGrnTabIndex = _poGrnTabController.index;
        // Refresh data when switching between PO and GRN tabs
        if (_poGrnTabController.index == 0) {
          // PO tab selected - refresh PO orders
          _loadPOOrders();
        } else if (_poGrnTabController.index == 1) {
          // GRN tab selected - refresh GRN orders
          _loadGrnOrders();
        }
      }
    });

    _inventoryTabController.addListener(() {
      if (_inventoryTabController.index != _previousInventoryTabIndex) {
        _previousInventoryTabIndex = _inventoryTabController.index;
        // Refresh data when switching between Inventory sub-tabs
        if (_inventoryTabController.index == 0) {
          // Materials tab selected - refresh materials
          _loadMaterials();
        }
      }
    });

    // Load materials when inventory tab is selected
    _loadMaterials();
    // Load PO orders when PO tab is selected
    _loadPOOrders();
    // Load GRN orders
    _loadGrnOrders();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _poGrnTabController.dispose();
    _inventoryTabController.dispose();
    _searchController.dispose();
    _poSearchController.dispose();
    _grnSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getMaterials(
        siteId: widget.site.id,
        page: 1,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

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

  Future<void> _loadGrnOrders() async {
    setState(() {
      _isLoadingGRN = true;
    });

    try {
      final response = await ApiService.getGrnList(siteId: widget.site.id);

      if (response != null && response.status == 1) {
        setState(() {
          _grnOrders = response.data ?? [];
          _filteredGrnOrders = response.data ?? [];
        });
      } else {
        setState(() {
          _grnOrders = [];
          _filteredGrnOrders = [];
        });
      }
    } catch (e) {
      setState(() {
        _grnOrders = [];
        _filteredGrnOrders = [];
      });
    } finally {
      setState(() {
        _isLoadingGRN = false;
      });
    }
  }

  Future<void> _refreshGrnOrders() async {
    setState(() {
      _isRefreshingGRN = true;
    });

    await _loadGrnOrders();

    setState(() {
      _isRefreshingGRN = false;
    });
  }

  void _filterGrnOrders(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredGrnOrders = _grnOrders;
        } else {
          _filteredGrnOrders = _grnOrders.where((grn) {
            return grn['grn_number']?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ==
                    true ||
                grn['delivery_challan_number']?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ==
                    true ||
                grn['remarks']?.toLowerCase().contains(query.toLowerCase()) ==
                    true;
          }).toList();
        }
      });
    }
  }

  void _showGrnCreationOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Create GRN',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Options
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Option 1: Select Materials through Inventory
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await NavigationUtils.push(
                          context,
                          GrnMaterialSelectionScreen(site: widget.site),
                        );
                        // Refresh GRN list if GRN was created successfully
                        if (result == true) {
                          _loadGrnOrders();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Materials through Inventory',
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Choose materials from your inventory',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Option 2: Upload photos to create GRN
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await NavigationUtils.push(
                          context,
                          RecordGrnScreen(
                            site: widget.site,
                            selectedMaterials:
                                null, // No materials needed for photo upload flow
                          ),
                        );
                        // Refresh GRN list if GRN was created successfully
                        if (result == true) {
                          _loadGrnOrders();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upload photos to create GRN',
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Create GRN by uploading receipt photos',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      floatingActionButton: _currentMainTabIndex == 0
          ? _poGrnTabController.index == 0
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      final result = await NavigationUtils.push(
                        context,
                        CreatePOScreen(site: widget.site),
                      );
                      // Refresh PO list if PO was created successfully
                      if (result == true) {
                        _loadPOOrders();
                      }
                    },
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    icon: Icon(Icons.add),
                    label: Text('Add PO'),
                  )
                : FloatingActionButton.extended(
                    onPressed: () {
                      _showGrnCreationOptions();
                    },
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    icon: Icon(Icons.add),
                    label: Text('Add GRN'),
                  )
          : _currentMainTabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await NavigationUtils.push(
                  context,
                  AddMaterialScreen(site: widget.site),
                );
                // Refresh materials list if material was added successfully
                if (result == true) {
                  _loadMaterials();
                }
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
              controller: _mainTabController,
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
              controller: _mainTabController,
              children: [
                // PO & Delivery Tab with sub-tabs
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
    return Column(
      children: [
        // Sub-tab bar for PO and GRN
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _poGrnTabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 2,
            labelStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'PO'),
              Tab(text: 'GRN'),
            ],
          ),
        ),

        // Sub-tab content
        Expanded(
          child: TabBarView(
            controller: _poGrnTabController,
            children: [
              // PO Tab
              _buildPOTab(),

              // GRN Tab
              _buildGrnTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPOTab() {
    if (_isLoadingPO) {
      return Center(child: CircularProgressIndicator());
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

          // PO Orders List or Empty State
          Expanded(
            child: _filteredPOOrders.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refreshPOOrders,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: ResponsiveUtils.responsivePadding(context),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
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
                                onPressed: () async {
                                  final result = await NavigationUtils.push(
                                    context,
                                    CreatePOScreen(site: widget.site),
                                  );
                                  // Refresh PO list if PO was created successfully
                                  if (result == true) {
                                    _loadPOOrders();
                                  }
                                },
                                icon: Icon(Icons.add),
                                label: Text('Create Purchase Order'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
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

  Widget _buildGrnTab() {
    if (_isLoadingGRN) {
      return Center(child: CircularProgressIndicator());
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
              hintText: 'Search GRN orders...',
              onChanged: _filterGrnOrders,
              controller: _grnSearchController,
            ),
          ),

          // GRN Orders List or Empty State
          Expanded(
            child: _filteredGrnOrders.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refreshGrnOrders,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: ResponsiveUtils.responsivePadding(context),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
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
                                'No GRN records found',
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
                                'GRN records will appear here once materials are received',
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshGrnOrders,
                    child: ListView.builder(
                      padding: ResponsiveUtils.responsivePadding(context),
                      itemCount: _filteredGrnOrders.length,
                      itemBuilder: (context, index) {
                        final grnOrder = _filteredGrnOrders[index];
                        return _buildGrnCard(grnOrder);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Column(
      children: [
        // Sub-tab bar for Materials, Issue, Returns
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _inventoryTabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 2,
            labelStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'Materials'),
              Tab(text: 'Transfer'),
              Tab(text: 'Returns'),
            ],
          ),
        ),

        // Sub-tab content
        Expanded(
          child: TabBarView(
            controller: _inventoryTabController,
            children: [
              // Materials Tab
              _buildMaterialsTab(),

              // Transfer Tab
              _buildTransferTab(),

              // Returns Tab
              _buildReturnsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
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

          // Materials List or Empty State
          Expanded(
            child: _filteredMaterials.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refreshMaterials,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: ResponsiveUtils.responsivePadding(context),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
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

  Widget _buildTransferTab() {
    return Container(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
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
              'Material Transfer',
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
              'Material transfer functionality coming soon',
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
          ],
        ),
      ),
    );
  }

  Widget _buildReturnsTab() {
    return Container(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return_outlined,
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
              'Material Returns',
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
              'Material returns functionality coming soon',
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
          ],
        ),
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
            siteId: widget.site.id,
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
              SizedBox(height: 2),
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
              SizedBox(height: 2),
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
              SizedBox(height: 2),
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
              SizedBox(height: 2),
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
            SizedBox(height: 2),
            Divider(),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPOCard(POModel poOrder) {
    Color _getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'open':
          return const Color(0xFF2196F3); // Blue - solid color
        case 'closed':
          return const Color(0xFF4CAF50); // Green - solid color
        case 'ordered':
          return const Color(0xFF2196F3); // Blue - solid color
        case 'delivered':
          return const Color(0xFF4CAF50); // Green - solid color
        case 'pending':
          return const Color(0xFFFF9800); // Orange - solid color
        case 'approved':
          return const Color(0xFF4CAF50); // Green - solid color
        case 'rejected':
          return const Color(0xFFF44336); // Red - solid color
        default:
          return const Color(0xFF9E9E9E); // Grey - solid color
      }
    }

    Color _getStatus2Color(String? status2) {
      if (status2 == null) return const Color(0xFF9E9E9E); // Grey - solid color
      switch (status2.toLowerCase()) {
        case 'pending':
          return const Color(0xFFFF9800); // Orange - solid color
        case 'partially_delivered':
          return const Color(0xFFFFC107); // Amber/Yellow - solid color
        case 'delivered':
          return const Color(0xFF4CAF50); // Green - solid color
        default:
          return const Color(0xFF9E9E9E); // Grey - solid color
      }
    }

    String _getStatus2Label(String? status2) {
      if (status2 == null) return 'PENDING';
      switch (status2.toLowerCase()) {
        case 'pending':
          return 'PENDING';
        case 'partially_delivered':
          return 'PARTIALLY DELIVERED';
        case 'delivered':
          return 'DELIVERED';
        default:
          return 'PENDING';
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






    return GestureDetector(
      onTap: () async {
        final result = await NavigationUtils.push(
          context,
          PODetailScreen(
            materialPoId: poOrder.id,
            poNumber: poOrder.purchaseOrderId,
          ),
        );

        if (result == true) {
          _loadPOOrders();
        }
      },
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poOrder.purchaseOrderId,
              style: AppTypography.titleSmall.copyWith(color: Colors.grey[800]),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(poOrder.status),
                    borderRadius: BorderRadius.circular(6),
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
                    color: _getStatus2Color(poOrder.status2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatus2Label(poOrder.status2),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                    'Issue By',
                    poOrder.creatorName?.trim().isNotEmpty == true 
                        ? poOrder.creatorName! 
                        : (poOrder.billingCompanyName.isNotEmpty ? poOrder.billingCompanyName : '-'),
                  ),
                ),

                Expanded(
                  child: _buildDetailColumn(
                    'Vendor',
                    poOrder.vendorName,
                  ),
                ),

              ],

            ),
            SizedBox(height: 10),
            Text(
              "Expected Delivery : ${_formatDate(poOrder.expectedDeliveryDate)}",
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 8),
          ],
        ),
      ),
    );

  }

  Widget _buildGrnCard(dynamic grnOrder) {

    String _formatDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return '-';
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

    final grnId = grnOrder['id'];
    final _ = _expandedGrnIds.contains(grnId);


    return GestureDetector(
      onTap: () async {
        final result = await NavigationUtils.push(
          context,
          GrnDetailScreen(grnId: grnId),
        );

        if (result == true) {
          _loadPOOrders();
        }
      },
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grnOrder['grn_number'] ?? 'GRN-Unknown',
              style: AppTypography.titleSmall.copyWith(color: Colors.grey[800]),
            ),

            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                    'Created By',
                    '${grnOrder['creator_name'] ?? 'User'} | ${_formatDateTime(grnOrder['created_at'])}',
                  ),
                ),

                Expanded(
                  child: _buildDetailColumn(
                    'Vendor',
                    grnOrder['vendor_name'] ?? grnOrder['vendor_id']?.toString() ?? '-',
                  ),
                ),

              ],

            ),
            SizedBox(height: 10),
            // Text(
            //   "Expected Delivery : ${_formatDate(poOrder.expectedDeliveryDate)}",
            //   style: AppTypography.bodyMedium.copyWith(
            //     color: Colors.grey[700],
            //     fontSize: 14,
            //   ),
            // ),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 8),
          ],
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

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            color: AppColors.textSecondary,
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
              color: AppColors.textPrimary,
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
