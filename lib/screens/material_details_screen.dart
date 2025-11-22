import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/material_stock_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import 'update_stock_screen.dart';

class MaterialDetailsScreen extends StatefulWidget {
  final int materialId;
  final String materialName;
  final String siteName;
  final int siteId;

  const MaterialDetailsScreen({
    super.key,
    required this.materialId,
    required this.materialName,
    required this.siteName,
    required this.siteId,
  });

  @override
  State<MaterialDetailsScreen> createState() => _MaterialDetailsScreenState();
}

class _MaterialDetailsScreenState extends State<MaterialDetailsScreen> {
  MaterialStockModel? _materialStock;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter states
  String? _selectedUser;
  String? _selectedType;
  String? _selectedDuration;
  List<StockHistoryModel> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _loadMaterialStock();
  }

  Future<void> _loadMaterialStock() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getMaterialStock(
        materialId: widget.materialId,
        siteId: widget.siteId,
        page: 1,
      );

      if (response != null) {
        setState(() {
          _materialStock = response;
          _filteredData = response.data;
          _isLoading = false;
        });
        // Reset filters when new data is loaded
        _selectedUser = null;
        _selectedType = null;
        _selectedDuration = null;
      } else {
        setState(() {
          _errorMessage = 'Failed to load material details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading material details: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (_materialStock == null) return;



    List<StockHistoryModel> filtered = _materialStock!.data;

    // Filter by user
    if (_selectedUser != null && _selectedUser!.isNotEmpty && _selectedUser != 'All') {
      filtered = filtered.where((item) => 
        item.user?.fullName.toLowerCase().contains(_selectedUser!.toLowerCase()) ?? false
      ).toList();

    }

    // Filter by type
    if (_selectedType != null && _selectedType!.isNotEmpty && _selectedType != 'All') {
      filtered = filtered.where((item) => 
        item.type.toLowerCase() == _selectedType!.toLowerCase()
      ).toList();

    }

    // Filter by duration
    if (_selectedDuration != null && _selectedDuration!.isNotEmpty && _selectedDuration != 'All') {
      final now = DateTime.now();
      DateTime? startDate;
      
      switch (_selectedDuration) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Last 7 days':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Last 30 days':
          startDate = now.subtract(Duration(days: 30));
          break;
        case 'Last 3 months':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'Last 6 months':
          startDate = DateTime(now.year, now.month - 6, now.day);
          break;
      }
      
      if (startDate != null) {
        filtered = filtered.where((item) {
          try {
            final itemDate = DateTime.parse(item.createdAt);
            return itemDate.isAfter(startDate!);
          } catch (e) {
            return false;
          }
        }).toList();
      }
    }

    setState(() {
      _filteredData = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedUser = null;
      _selectedType = null;
      _selectedDuration = null;
      _filteredData = _materialStock?.data ?? [];
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildFilterModal(setModalState),
      ),
    );
  }

  Widget _buildFilterModal(Function setModalState) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content - Split Pane Layout
          Expanded(
            child: Row(
              children: [
                // Left Pane - Filter Categories
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      right: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: _buildFilterCategories(setModalState),
                ),
                
                // Right Pane - Filter Options
                Expanded(
                  child: _buildFilterOptions(setModalState),
                ),
              ],
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedUser = null;
                        _selectedType = null;
                        _selectedDuration = null;
                      });
                      _clearFilters();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Update parent state with current filter values
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  List<String> _getUniqueUsers() {
    if (_materialStock == null) return [];
    
    final users = _materialStock!.data
        .map((item) => item.user?.fullName ?? 'Unknown')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    
    users.sort();
    return ['All', ...users];
  }

  String _selectedCategory = 'Created By';

  Widget _buildFilterCategories(Function setModalState) {
    final categories = [
      {'name': 'Created By', 'icon': Icons.person},
      {'name': 'Type', 'icon': Icons.category},
      {'name': 'Duration', 'icon': Icons.schedule},
    ];

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryName = category['name'] as String;
        final isSelected = _selectedCategory == categoryName;
        
        return GestureDetector(
          onTap: () {
            setModalState(() {
              _selectedCategory = categoryName;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  category['icon'] as IconData,
                  size: 16,
                  color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: isSelected ? AppColors.primaryColor : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOptions(Function setModalState) {
    switch (_selectedCategory) {
      case 'Created By':
        return _buildUserFilterOptions(setModalState);
      case 'Type':
        return _buildTypeFilterOptions(setModalState);
      case 'Duration':
        return _buildDurationFilterOptions(setModalState);
      default:
        return _buildUserFilterOptions(setModalState);
    }
  }

  Widget _buildUserFilterOptions(Function setModalState) {
    final users = _getUniqueUsers();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          margin: EdgeInsets.all(12),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 14, color: Colors.grey[600]),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // User Options
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isSelected = _selectedUser == user;
              
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    _selectedUser = user;
                  });
                },
                                 child: Container(
                   padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                   child: Row(
                     children: [
                       Container(
                         width: 16,
                         height: 16,
                         decoration: BoxDecoration(
                           border: Border.all(
                             color: isSelected ? AppColors.primaryColor : Colors.grey[400]!,
                             width: 1.5,
                           ),
                           borderRadius: BorderRadius.circular(2),
                         ),
                         child: isSelected
                             ? Icon(
                                 Icons.check,
                                 size: 10,
                                 color: AppColors.primaryColor,
                               )
                             : null,
                       ),
                       SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           user,
                           style: TextStyle(
                             fontSize: 13,
                             fontWeight: FontWeight.w400,
                             color: Colors.black87,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilterOptions(Function setModalState) {
    final types = ['GRN', 'Material Issue', 'Task', 'Site Transfer'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Select Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = _selectedType == type;
              
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    _selectedType = isSelected ? null : type;
                  });
                },
                                 child: Container(
                   padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                   child: Row(
                     children: [
                       Container(
                         width: 16,
                         height: 16,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border: Border.all(
                             color: isSelected ? AppColors.primaryColor : Colors.grey[400]!,
                             width: 1.5,
                           ),
                         ),
                         child: isSelected
                             ? Container(
                                 margin: EdgeInsets.all(2.5),
                                 decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   color: AppColors.primaryColor,
                                 ),
                               )
                             : null,
                       ),
                       SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           type,
                           style: TextStyle(
                             fontSize: 13,
                             fontWeight: FontWeight.w400,
                             color: Colors.black87,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDurationFilterOptions(Function setModalState) {
    final durations = ['Today', 'Last 3 days', 'Last 7 days', 'Last 15 days', 'Specific date'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Input Fields
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Select Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Select End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Duration Options
        Expanded(
          child: ListView.builder(
            itemCount: durations.length,
            itemBuilder: (context, index) {
              final duration = durations[index];
              final isSelected = _selectedDuration == duration;
              
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    _selectedDuration = isSelected ? null : duration;
                  });
                },
                                 child: Container(
                   padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                   child: Row(
                     children: [
                       Container(
                         width: 16,
                         height: 16,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border: Border.all(
                             color: isSelected ? AppColors.primaryColor : Colors.grey[400]!,
                             width: 1.5,
                           ),
                         ),
                         child: isSelected
                             ? Container(
                                 margin: EdgeInsets.all(2.5),
                                 decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   color: AppColors.primaryColor,
                                 ),
                               )
                             : null,
                       ),
                       SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           duration,
                           style: TextStyle(
                             fontSize: 13,
                             fontWeight: FontWeight.w400,
                             color: Colors.black87,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _refreshData() async {
    await _loadMaterialStock();
  }

  bool _hasActiveFilters() {
    return _selectedUser != null || _selectedType != null || _selectedDuration != null;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedUser != null) count++;
    if (_selectedType != null) count++;
    if (_selectedDuration != null) count++;
    return count;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM, yyyy h:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStockStatusColor() {
    if (_materialStock == null) return Colors.grey;

    final currentStock = double.tryParse(_materialStock!.currentStock) ?? 0;
    final minStock = _materialStock!.material.minStock;

    if (currentStock > minStock) {
      return Colors.green;
    } else if (currentStock == minStock) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getStockStatusText() {
    if (_materialStock == null) return 'Unknown';

    final currentStock = double.tryParse(_materialStock!.currentStock) ?? 0;
    final minStock = _materialStock!.material.minStock;

    if (currentStock > minStock) {
      return 'OK';
    } else if (currentStock == minStock) {
      return 'Low';
    } else {
      return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.materialName,
        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _materialStock == null
          ? _buildEmptyState()
          : _buildContent(),
      bottomNavigationBar: _materialStock != null
          ? _buildBottomButtons()
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(onPressed: _loadMaterialStock, child: Text('Retry')),
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
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No Material Data',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Material details not found',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Information Section
            _buildMaterialInfoSection(),

            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceColor),
              child: Text(
                'STOCK SUMMARY',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: AppColors.darkBorder,
                ),
              ),
            ),
            SizedBox(height: 2),
            _buildStockSummarySection(),
            SizedBox(height: 16),

            // Project Stock History Section
            _buildStockHistorySection(),
            SizedBox(height: 80), // Space for bottom buttons
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialInfoSection() {
    final material = _materialStock!.material;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.name,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 4),
          Text(
            material.specification,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                'View Details',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryColor,
                size: 18,
              ),
            ],
          ),
          SizedBox(height: 20),

          // Stock Alert Section
          _buildStockAlertSection(),
        ],
      ),
    );
  }

  Widget _buildStockAlertSection() {
    final currentStock = double.tryParse(_materialStock!.currentStock) ?? 0;
    final minStock = _materialStock!.material.minStock;
    final unit = _materialStock!.material.unitOfMeasurement;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
            decoration: BoxDecoration(
              color: _getStockStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                topLeft: Radius.circular(12),
              ),

            ),
            child:  Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStockStatusColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStockStatusText(),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stock above alert (min. ${minStock} ${unit})',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),



          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project In stock Qty',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.darkBorder,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${currentStock.toStringAsFixed(0)} ${unit}',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Balance Qty',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.darkBorder,
                      ),
                    ),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to add estimate screen
                        SnackBarUtils.showInfo(
                          context,
                          message: 'Add estimate functionality coming soon',
                        );
                      },
                      child: Text(
                        '+ Add estimate',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummarySection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Added',
                  _materialStock!.totalIn.toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Used',
                  _materialStock!.totalOut.toString(),
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStockHistorySection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROJECT STOCK HISTORY',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.darkBorder,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showFilterModal();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: _hasActiveFilters() ? Colors.orange : AppColors.primaryColor,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Filters${_hasActiveFilters() ? ' (${_getActiveFilterCount()})' : ''}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _hasActiveFilters() ? Colors.orange : AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(color: AppColors.borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Entry',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: AppColors.borderColor),
                Expanded(
                  flex: 1,
                  child: Text(
                    'In Stock',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(width: 1, height: 20, color: AppColors.borderColor),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qty',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          if (_filteredData.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 8),
                  Text(
                    'No stock history available',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._filteredData
                .map((history) => _buildHistoryItem(history))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(StockHistoryModel history) {
    final isIn = history.type.toLowerCase() == 'in';
    final quantity = double.tryParse(history.quantity) ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isIn
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Entry Column (flex: 3)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHistoryDescription(history),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                if (history.grn != null) ...[
                  SizedBox(height: 1),
                  Text(
                    history.grn!.grnNumber,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (history.progressId != null) ...[
                  SizedBox(height: 1),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: ${history.progress['work_done']?.toString() ?? 'N/A'}%',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Remark: ${history.progress['remark']?.toString() ?? 'N/A'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 1),
                Text(
                  'Updated By ${history.user?.fullName ?? 'Unknown'} on ${_formatDate(history.createdAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Vertical separator
          Container(width: 1, height: 60, color: AppColors.borderColor),

          // In Stock Column (flex: 1)
          Expanded(
            flex: 1,
            child: Text(
              history.currentStock?.toString() ?? 'N/A',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: isIn ? Colors.green : Colors.red,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Vertical separator
          Container(width: 1, height: 60, color: AppColors.borderColor),

          // Qty Column (flex: 1)
          Expanded(
            flex: 1,
            child: Text(
              '${isIn ? '+' : '-'}${quantity.toStringAsFixed(0)}',
              style: AppTypography.bodySmall.copyWith(
                color: isIn ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

    String _getHistoryDescription(StockHistoryModel history) {
    switch (history.type.toLowerCase()) {
      case 'in':
        if (history.grn != null) {
          return 'Received from ${history.grn!.deliveryChallanNumber}';
        } else {
          return 'Added to stock';
        }
      case 'out':
        if (history.progressId != null) {
          // For task usage, show work done and remark if available
          String description = 'Used on Task';
          
          return description;
        } else {
          return 'Used from stock';
        }
      default:
        return history.description.isNotEmpty ? history.description : 'Stock transaction';
    }
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      child: ElevatedButton(
        onPressed: () {
          NavigationUtils.push(
            context,
            UpdateStockScreen(
              material: _materialStock!.material,
              currentStock: _materialStock!.currentStock,
              siteName: widget.siteName,
              siteId: widget.siteId,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Update Stock',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

