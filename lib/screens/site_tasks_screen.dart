import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/tag_model.dart';
import '../models/site_user_model.dart';
import '../models/category_model.dart';
import '../models/qc_category_model.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_search_bar.dart';
import '../screens/create_task_screen.dart';
import '../widgets/custom_button.dart';
import '../core/utils/navigation_utils.dart';
import 'dart:async';

class _FilterSearchWidget<T> extends StatefulWidget {
  final List<T> items;
  final List<int> selectedIds;
  final Function(int) onToggle;
  final String searchHint;
  final String Function(T) itemBuilder;
  final int Function(T) idExtractor;

  const _FilterSearchWidget({
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    required this.searchHint,
    required this.itemBuilder,
    required this.idExtractor,
  });

  @override
  State<_FilterSearchWidget<T>> createState() => _FilterSearchWidgetState<T>();
}

class _FilterSearchWidgetState<T> extends State<_FilterSearchWidget<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final itemText = widget.itemBuilder(item).toLowerCase();
          return itemText.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: CustomSearchBar(
            hintText: widget.searchHint,
            controller: _searchController,
            onChanged: (query) {
              // The search is handled by the controller listener
            },
            height: 40,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              final isSelected = widget.selectedIds.contains(
                widget.idExtractor(item),
              );
              return CheckboxListTile(
                title: Text(
                  widget.itemBuilder(item),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  widget.onToggle(widget.idExtractor(item));
                },
                activeColor: AppColors.primaryColor,
                checkColor: AppColors.textWhite,
              );
            },
          ),
        ),
      ],
    );
  }
}

class SiteTasksScreen extends StatefulWidget {
  final SiteModel site;

  const SiteTasksScreen({super.key, required this.site});

  @override
  State<SiteTasksScreen> createState() => _SiteTasksScreenState();
}

class _SiteTasksScreenState extends State<SiteTasksScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'all'; // Set default to 'all' to show all tasks

  // Filter data
  List<TagModel> _tags = [];
  List<SiteUserModel> _users = [];
  List<CategoryModel> _categories = [];
  List<QcCategoryModel> _qcCategories = [];

  // Selected filters
  List<int> _selectedAssignTo = [];
  List<int> _selectedCategories = [];
  List<int> _selectedTags = [];
  List<int> _selectedQcCategories = [];
  List<int> _selectedCreatedBy = [];
  List<int> _selectedUpdatedBy = [];
  DateTime? _startDate;
  DateTime? _endDate;

  // Sub-category selections
  List<String> _selectedDecisionByAgency = [];
  List<String> _selectedDrawingByAgency = [];
  List<String> _selectedSelectionByAgency = [];
  List<String> _selectedQuotationByAgency = [];

  // Loading states
  bool _isLoadingFilters = false;
  bool _isLoadingTasks = false;

  // Task list
  List<TaskModel> _tasks = [];
  int _totalTasks = 0;

  // Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // Selected filter for right column
  String _selectedFilterType =
      'assign'; // Set default to show Assign To initially

  // Scroll controller for pagination
  late ScrollController _scrollController;

  // Search debounce timer
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadFilterData();
    _loadTasks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTasks();
    }
  }

  Future<void> _loadFilterData() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      final String? apiToken = LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      // Load tags
      final tagResponse = await ApiService.getTags(apiToken: apiToken);
      if (tagResponse.isSuccess) {
        setState(() {
          _tags = tagResponse.data;
        });
      }

      // Load users (getUserBySite)
      final userResponse = await ApiService.getUsersBySite(
        apiToken: apiToken,
        siteId: widget.site.id,
      );
      if (userResponse.isSuccess) {
        setState(() {
          _users = userResponse.users;
        });
      }

      // Load categories (getCategoryBySiteId)
      final categoryResponse = await ApiService.getCategoriesBySite(
        apiToken: apiToken,
        siteId: widget.site.id,
      );
      if (categoryResponse.isSuccess) {
        setState(() {
          _categories = categoryResponse.categories;
        });
      }

      // Load QC categories (qcCategories)
      final qcCategoryResponse = await ApiService.getQcCategories(
        apiToken: apiToken,
      );
      if (qcCategoryResponse.isSuccess) {
        setState(() {
          _qcCategories = qcCategoryResponse.points;
        });
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to load filter data: $e',
      );
    } finally {
      setState(() {
        _isLoadingFilters = false;
      });
    }
  }

  Future<void> _loadTasks({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoadingTasks = true;
        _currentPage = 1; // Reset to first page when loading fresh
        _hasMorePages = true;
      });
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

      // Build filters map
      Map<String, dynamic> filters = {};

      // Add search query to filters
      if (_searchQuery.isNotEmpty) {
        filters['search'] = _searchQuery.trim();
      }

      if (_selectedStatus.isNotEmpty) {
        // Handle Survey filter separately (sub_cat = 1)
        if (_selectedStatus == 'survey') {
          filters['showSurvey'] = '1';
        } else {
          // Map UI status to API status values
          String apiStatus = '';
          switch (_selectedStatus) {
            case 'all':
              apiStatus = '';
              break;
            case 'pending':
              apiStatus = 'Pending';
              break;
            case 'in_progress':
              apiStatus = 'Active';
              break;
            case 'completed':
              apiStatus = 'Complete';
              break;
            case 'overdue':
              apiStatus = 'Overdue';
              break;
            default:
              apiStatus = _selectedStatus;
          }
          filters['status'] = apiStatus;
          filters['showSurvey'] = '2';
        }
      }
      if (_selectedAssignTo.isNotEmpty) {
        filters['assign_to'] = _selectedAssignTo.join(',');
      }
      if (_selectedCategories.isNotEmpty) {
        filters['category_id'] = _selectedCategories.join(',');
      }
      if (_selectedTags.isNotEmpty) {
        filters['tag'] = _selectedTags.join(',');
      }
      if (_selectedQcCategories.isNotEmpty) {
        filters['qc_category_id'] = _selectedQcCategories.join(',');
      }
      if (_selectedCreatedBy.isNotEmpty) {
        filters['created_by'] = _selectedCreatedBy.join(',');
      }
      if (_selectedUpdatedBy.isNotEmpty) {
        filters['updated_by'] = _selectedUpdatedBy.join(',');
      }
      if (_startDate != null) {
        filters['start_date'] = _startDate!.toIso8601String().split('T')[0];
      }
      if (_endDate != null) {
        filters['end_date'] = _endDate!.toIso8601String().split('T')[0];
      }

      // Add agency filters
      if (_selectedDecisionByAgency.isNotEmpty) {
        filters['decision_by_agency'] = _selectedDecisionByAgency.join(',');
      }
      if (_selectedDrawingByAgency.isNotEmpty) {
        filters['drawing_by_agency'] = _selectedDrawingByAgency.join(',');
      }
      if (_selectedSelectionByAgency.isNotEmpty) {
        filters['selection_by_agency'] = _selectedSelectionByAgency.join(',');
      }
      if (_selectedQuotationByAgency.isNotEmpty) {
        filters['quotation_by_agency'] = _selectedQuotationByAgency.join(',');
      }

      // Add pagination
      filters['page'] = _currentPage;

      // Log all filters being passed to API
      print('🔍 === TASK FILTERS LOG ===');
      print('📍 Site ID: ${widget.site.id}');
      print('📄 Current Page: $_currentPage');
      print('🔍 Search Query: "${_searchQuery}"');
      print('🏷️ Selected Status: "${_selectedStatus}"');
      print('📊 Total Filters: ${filters.length}');
      print('📋 Filters Map:');
      filters.forEach((key, value) {
        print('   • $key: $value');
      });
      if (filters.isEmpty) {
        print('   • No filters applied');
      }
      print('🔍 === END FILTERS LOG ===');

      final taskResponse = await ApiService.getTaskList(
        apiToken: apiToken,
        siteId: widget.site.id,
        filters: filters.isNotEmpty ? filters : null,
      );

      // Debug: Log the response details
      print('🔍 === TASK RESPONSE DEBUG ===');
      print('📊 Response Status: ${taskResponse.status}');
      print('📊 Is Success: ${taskResponse.isSuccess}');
      print('📊 Total Tasks: ${taskResponse.totalTasks}');
      print('📊 Data Length: ${taskResponse.data.length}');
      print('🔍 === END RESPONSE DEBUG ===');

      // Check if we have data, even if status is not 1
      if (taskResponse.data.isNotEmpty || taskResponse.status == 1) {
        setState(() {
          if (_currentPage == 1) {
            // First page - replace all tasks
            _tasks = taskResponse.data;
          } else {
            // Subsequent pages - append tasks
            _tasks.addAll(taskResponse.data);
          }
          _totalTasks = taskResponse.totalTasks;

          // Check if there are more pages
          _hasMorePages =
              taskResponse.data.isNotEmpty && _tasks.length < _totalTasks;
        });
      } else {
        // Only show error if we have no data and status is not 1
        if (taskResponse.status != 1) {
          SnackBarUtils.showError(context, message: 'Failed to load tasks');
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to load tasks: $e');
    } finally {
      setState(() {
        if (isLoadMore) {
          _isLoadingMore = false;
        } else {
          _isLoadingTasks = false;
        }
      });
    }
  }

  Future<void> _loadMoreTasks() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _currentPage++;
    });

    await _loadTasks(isLoadMore: true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: ResponsiveUtils.responsivePadding(context),
                  child: CustomSearchBar(
                    hintText: 'Search tasks...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });

                      // Cancel previous timer
                      _searchDebounceTimer?.cancel();

                      // Set new timer for debounced search
                      _searchDebounceTimer = Timer(
                        Duration(milliseconds: 500),
                        () {
                          // Reset pagination and reload tasks when search changes
                          _currentPage = 1;
                          _hasMorePages = true;
                          _loadTasks();
                        },
                      );
                    },
                  ),
                ),

                // Sort and Filter Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Filter Button
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus(); // Dismiss keyboard
                          _showFilterOptions();
                        },
                        child: Container(
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
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.responsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 12,
                                desktop: 16,
                              ),
                            ),
                            border: Border.all(
                              color: AppColors.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                size: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 4,
                                  tablet: 6,
                                  desktop: 8,
                                ),
                              ),
                              Text(
                                'Filters',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 12,
                                    tablet: 14,
                                    desktop: 16,
                                  ),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
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

                      // Filter Chips
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              SizedBox(
                                width: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16,
                                ),
                              ),
                              _buildFilterChip('Pending', 'pending'),
                              SizedBox(
                                width: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16,
                                ),
                              ),
                              _buildFilterChip('In Progress', 'in_progress'),
                              SizedBox(
                                width: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16,
                                ),
                              ),
                              _buildFilterChip('Completed', 'completed'),
                              SizedBox(
                                width: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16,
                                ),
                              ),
                              _buildFilterChip('Overdue', 'overdue'),
                              SizedBox(
                                width: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16,
                                ),
                              ),
                              _buildFilterChip('Survey', 'survey'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Task List
                Expanded(child: _buildTaskList()),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: ResponsiveUtils.responsivePadding(context),
                width: double.infinity,
                child: CustomButton(
                  onPressed: () async {
                    final result = await NavigationUtils.push(
                      context,
                      CreateTaskScreen(site: widget.site),
                    );
                    // If task was created successfully, refresh the task list
                    if (result == true) {
                      setState(() {
                        _currentPage = 1;
                        _hasMorePages = true;
                      });
                      await _loadTasks();
                    }
                  },
                  text: 'Create Task',
                  prefixIcon: Icon(Icons.add, color: AppColors.textWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFilterCount() {
    int count = 0;
    if (_selectedAssignTo.isNotEmpty) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_selectedTags.isNotEmpty) count++;
    if (_selectedQcCategories.isNotEmpty) count++;
    if (_selectedCreatedBy.isNotEmpty) count++;
    if (_selectedUpdatedBy.isNotEmpty) count++;
    if (_startDate != null || _endDate != null) count++;
    if (_selectedStatus.isNotEmpty) count++;
    return count;
  }

  // Get comma-separated sub-category data
  String _getSubCategoryData() {
    List<String> data = [];

    if (_selectedDecisionByAgency.isNotEmpty) {
      data.add('decision_by_agency: ${_selectedDecisionByAgency.join(", ")}');
    }
    if (_selectedDrawingByAgency.isNotEmpty) {
      data.add('drawing_by_agency: ${_selectedDrawingByAgency.join(", ")}');
    }
    if (_selectedSelectionByAgency.isNotEmpty) {
      data.add('selection_by_agency: ${_selectedSelectionByAgency.join(", ")}');
    }
    if (_selectedQuotationByAgency.isNotEmpty) {
      data.add('quotation_by_agency: ${_selectedQuotationByAgency.join(", ")}');
    }

    return data.join(" | ");
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
        setState(() {
          // For 'all' status, don't allow deselecting (always keep it selected)
          if (status == 'all') {
            _selectedStatus = 'all';
          } else {
            _selectedStatus = isSelected ? 'all' : status;
          }
        });
        // Reload tasks when status filter changes
        _loadTasks();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
          vertical: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 6,
            tablet: 8,
            desktop: 10,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedAssignTo.clear();
                          _selectedCategories.clear();
                          _selectedTags.clear();
                          _selectedQcCategories.clear();
                          _selectedCreatedBy.clear();
                          _selectedUpdatedBy.clear();
                          _startDate = null;
                          _endDate = null;
                          _selectedStatus = 'all'; // Reset to 'all' instead of empty
                          _selectedDecisionByAgency.clear();
                          _selectedDrawingByAgency.clear();
                          _selectedSelectionByAgency.clear();
                          _selectedQuotationByAgency.clear();
                        });
                        Navigator.pop(context);
                        // Reload tasks after clearing filters
                        _loadTasks();
                      },
                      child: Text(
                        'Clear All',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column - Filter Titles
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFilterTitle(
                                'Assign To',
                                _selectedAssignTo.length,
                                () {
                                  _selectFilter('assign');
                                  setModalState(() {}); // Force modal rebuild
                                },
                              ),
                              _buildFilterTitle(
                                'Work Categories',
                                _selectedCategories.length,
                                () {
                                  _selectFilter('categories');
                                  setModalState(() {}); // Force modal rebuild
                                },
                              ),
                              _buildFilterTitle(
                                'Tags',
                                _selectedTags.length,
                                () {
                                  _selectFilter('tags');
                                  setModalState(() {}); // Force modal rebuild
                                },
                              ),
                              _buildFilterTitle(
                                'QC Categories',
                                _selectedQcCategories.length,
                                () {
                                  _selectFilter('qc_categories');
                                  setModalState(() {}); // Force modal rebuild
                                },
                              ),
                              _buildFilterTitle(
                                'Created By',
                                _selectedCreatedBy.length,
                                () {
                                  _selectFilter('created_by');
                                  setModalState(() {}); // Force modal rebuild
                                },
                              ),
                              _buildFilterTitle(
                                'Updated By',
                                _selectedUpdatedBy.length,
                                () {
                                  _selectFilter('updated_by');
                                  setModalState(() {}); // Force modal rebuild
                                },
                              ),

                              // Sub-category filters - show only when corresponding category is selected
                              ...(() {
                                List<Widget> widgets = [];

                                // Check for Decision
                                if (_selectedCategories.any((id) {
                                  try {
                                    final category = _categories.firstWhere(
                                      (cat) => cat.id == id,
                                    );
                                    final result =
                                        category.name.toLowerCase() ==
                                        'decision';

                                    return result;
                                  } catch (e) {
                                    return false;
                                  }
                                })) {
                                  widgets.add(
                                    _buildFilterTitle(
                                      'Decision by Agency',
                                      _selectedDecisionByAgency.length,
                                      () {
                                        _selectFilter('decision_by_agency');
                                        setModalState(
                                          () {},
                                        ); // Force modal rebuild
                                      },
                                    ),
                                  );
                                }

                                // Check for Drawing
                                if (_selectedCategories.any((id) {
                                  try {
                                    final category = _categories.firstWhere(
                                      (cat) => cat.id == id,
                                    );
                                    return category.name.toLowerCase() ==
                                        'drawing';
                                  } catch (e) {
                                    return false;
                                  }
                                })) {
                                  widgets.add(
                                    _buildFilterTitle(
                                      'Drawing by Agency',
                                      _selectedDrawingByAgency.length,
                                      () {
                                        _selectFilter('drawing_by_agency');
                                        setModalState(
                                          () {},
                                        ); // Force modal rebuild
                                      },
                                    ),
                                  );
                                }

                                // Check for Selection
                                if (_selectedCategories.any((id) {
                                  try {
                                    final category = _categories.firstWhere(
                                      (cat) => cat.id == id,
                                    );
                                    return category.name.toLowerCase() ==
                                        'selection';
                                  } catch (e) {
                                    return false;
                                  }
                                })) {
                                  widgets.add(
                                    _buildFilterTitle(
                                      'Selection by Agency',
                                      _selectedSelectionByAgency.length,
                                      () {
                                        _selectFilter('selection_by_agency');
                                        setModalState(
                                          () {},
                                        ); // Force modal rebuild
                                      },
                                    ),
                                  );
                                }

                                // Check for Quotation
                                if (_selectedCategories.any((id) {
                                  try {
                                    final category = _categories.firstWhere(
                                      (cat) => cat.id == id,
                                    );
                                    return category.name.toLowerCase() ==
                                        'quotation';
                                  } catch (e) {
                                    return false;
                                  }
                                })) {
                                  widgets.add(
                                    _buildFilterTitle(
                                      'Quotation by Agency',
                                      _selectedQuotationByAgency.length,
                                      () {
                                        _selectFilter('quotation_by_agency');
                                        setModalState(
                                          () {},
                                        ); // Force modal rebuild
                                      },
                                    ),
                                  );
                                }

                                return widgets;
                              })(),

                              _buildFilterTitle(
                                'Date Range',
                                (_startDate != null || _endDate != null)
                                    ? 1
                                    : 0,
                                () {
                                  _selectFilter('date_range');
                                  setModalState(() {}); // Force modal rebuild
                                },
                              ),
                              SizedBox(
                                height: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  desktop: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        color: AppColors.borderColor,
                        margin: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                      ),

                      // Right Column - Filter Options
                      Expanded(
                        flex: 3,
                        child: _buildFilterOptions(setModalState),
                      ),
                    ],
                  ),
                ),
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Get all selected data
                      String subCategoryData = _getSubCategoryData();
                      if (subCategoryData.isNotEmpty) {
                        print('Sub-category data: $subCategoryData');
                      }
                      Navigator.pop(context);
                      // Reload tasks with applied filters
                      _loadTasks();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTitle(
    String title,
    int selectedCount,
    VoidCallback onTap,
  ) {
    // Map title to filter type for proper matching
    String getFilterType(String title) {
      switch (title) {
        case 'Assign To':
          return 'assign';
        case 'Work Categories':
          return 'categories';
        case 'Tags':
          return 'tags';
        case 'QC Categories':
          return 'qc_categories';
        case 'Created By':
          return 'created_by';
        case 'Updated By':
          return 'updated_by';
        case 'Date Range':
          return 'date_range';
        case 'Decision by Agency':
          return 'decision_by_agency';
        case 'Drawing by Agency':
          return 'drawing_by_agency';
        case 'Selection by Agency':
          return 'selection_by_agency';
        case 'Quotation by Agency':
          return 'quotation_by_agency';
        default:
          return '';
      }
    }

    final filterType = getFilterType(title);
    final isSelected = _selectedFilterType == filterType;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selectedCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  selectedCount.toString(),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 10,
                      tablet: 12,
                      desktop: 14,
                    ),
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectFilter(String filterType) {
    setState(() {
      _selectedFilterType = filterType;
    });
  }

  Widget _buildFilterOptions(StateSetter setModalState) {
    switch (_selectedFilterType) {
      case 'assign':
        return _buildUserOptions(_selectedAssignTo, (userId) {
          setModalState(() {
            if (_selectedAssignTo.contains(userId)) {
              _selectedAssignTo.remove(userId);
            } else {
              _selectedAssignTo.add(userId);
            }
          });
        });
      case 'categories':
        return _buildCategoryOptions(_selectedCategories, (categoryId) {
          setModalState(() {
            if (_selectedCategories.contains(categoryId)) {
              _selectedCategories.remove(categoryId);
            } else {
              _selectedCategories.add(categoryId);
            }
          });
        });
      case 'tags':
        return _buildTagOptions(_selectedTags, (tagId) {
          setModalState(() {
            if (_selectedTags.contains(tagId)) {
              _selectedTags.remove(tagId);
            } else {
              _selectedTags.add(tagId);
            }
          });
        });
      case 'qc_categories':
        return _buildQcCategoryOptions(_selectedQcCategories, (qcCategoryId) {
          setModalState(() {
            if (_selectedQcCategories.contains(qcCategoryId)) {
              _selectedQcCategories.remove(qcCategoryId);
            } else {
              _selectedQcCategories.add(qcCategoryId);
            }
          });
        });
      case 'created_by':
        return _buildUserOptions(_selectedCreatedBy, (userId) {
          setModalState(() {
            if (_selectedCreatedBy.contains(userId)) {
              _selectedCreatedBy.remove(userId);
            } else {
              _selectedCreatedBy.add(userId);
            }
          });
        });
      case 'updated_by':
        return _buildUserOptions(_selectedUpdatedBy, (userId) {
          setModalState(() {
            if (_selectedUpdatedBy.contains(userId)) {
              _selectedUpdatedBy.remove(userId);
            } else {
              _selectedUpdatedBy.add(userId);
            }
          });
        });
      case 'decision_by_agency':
        return _buildAgencyOptions(
          'Decision by Agency',
          _selectedDecisionByAgency,
          (agency) {
            setModalState(() {
              if (_selectedDecisionByAgency.contains(agency)) {
                _selectedDecisionByAgency.remove(agency);
              } else {
                _selectedDecisionByAgency.add(agency);
              }
            });
          },
        );
      case 'drawing_by_agency':
        return _buildAgencyOptions(
          'Drawing by Agency',
          _selectedDrawingByAgency,
          (agency) {
            setModalState(() {
              if (_selectedDrawingByAgency.contains(agency)) {
                _selectedDrawingByAgency.remove(agency);
              } else {
                _selectedDrawingByAgency.add(agency);
              }
            });
          },
        );
      case 'selection_by_agency':
        return _buildAgencyOptions(
          'Selection by Agency',
          _selectedSelectionByAgency,
          (agency) {
            setModalState(() {
              if (_selectedSelectionByAgency.contains(agency)) {
                _selectedSelectionByAgency.remove(agency);
              } else {
                _selectedSelectionByAgency.add(agency);
              }
            });
          },
        );
      case 'quotation_by_agency':
        return _buildAgencyOptions(
          'Quotation by Agency',
          _selectedQuotationByAgency,
          (agency) {
            setModalState(() {
              if (_selectedQuotationByAgency.contains(agency)) {
                _selectedQuotationByAgency.remove(agency);
              } else {
                _selectedQuotationByAgency.add(agency);
              }
            });
          },
        );
      case 'date_range':
        return _buildDateRangeOptions();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_outlined,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 48,
                  tablet: 56,
                  desktop: 64,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 12,
                  tablet: 16,
                  desktop: 20,
                ),
              ),
              Text(
                'Select a filter from the left',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildUserOptions(List<int> selectedIds, Function(int) onToggle) {
    return _FilterSearchWidget<SiteUserModel>(
      items: _users,
      selectedIds: selectedIds,
      onToggle: onToggle,
      searchHint: 'Search users...',
      itemBuilder: (user) => '${user.firstName ?? ''} ${user.lastName ?? ''}',
      idExtractor: (user) => user.id,
    );
  }

  Widget _buildCategoryOptions(List<int> selectedIds, Function(int) onToggle) {
    return _FilterSearchWidget<CategoryModel>(
      items: _categories,
      selectedIds: selectedIds,
      onToggle: onToggle,
      searchHint: 'Search categories...',
      itemBuilder: (category) => category.name,
      idExtractor: (category) => category.id,
    );
  }

  Widget _buildAgencyOptions(
    String title,
    List<String> selectedOptions,
    Function(String) onToggle,
  ) {
    List<String> options = [];

    switch (title) {
      case 'Decision by Agency':
        options = [
          "PMC",
          "Client",
          "Architect",
          "Vendor",
          "Structure",
          "Other",
        ];
        break;
      case 'Drawing by Agency':
        options = ["Architect", "Structure", "Other"];
        break;
      case 'Selection by Agency':
        options = ["Architect", "Client"];
        break;
      case 'Quotation by Agency':
        options = ["Architect", "Structure", "Other"];
        break;
      default:
        options = [];
    }

    return _FilterSearchWidget<String>(
      items: options,
      selectedIds: selectedOptions.map((e) => e.hashCode).toList(),
      onToggle: (id) {
        final option = options.firstWhere((e) => e.hashCode == id);
        onToggle(option);
      },
      searchHint: 'Search agencies...',
      itemBuilder: (option) => option,
      idExtractor: (option) => option.hashCode,
    );
  }

  Widget _buildTagOptions(List<int> selectedIds, Function(int) onToggle) {
    return _FilterSearchWidget<TagModel>(
      items: _tags,
      selectedIds: selectedIds,
      onToggle: onToggle,
      searchHint: 'Search tags...',
      itemBuilder: (tag) => tag.name,
      idExtractor: (tag) => tag.id,
    );
  }

  Widget _buildQcCategoryOptions(
    List<int> selectedIds,
    Function(int) onToggle,
  ) {
    return _FilterSearchWidget<QcCategoryModel>(
      items: _qcCategories,
      selectedIds: selectedIds,
      onToggle: onToggle,
      searchHint: 'Search QC categories...',
      itemBuilder: (qcCategory) => qcCategory.name,
      idExtractor: (qcCategory) => qcCategory.id,
    );
  }

  Widget _buildDateRangeOptions() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start Date
                    Text(
                      'Start Date',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
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
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            _startDate = picked;
                          });
                          setState(() {
                            _startDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _startDate != null
                                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                  : 'Select Start Date',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _startDate != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.textSecondary,
                              size: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 24,
                        tablet: 28,
                        desktop: 32,
                      ),
                    ),

                    // End Date
                    Text(
                      'End Date',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
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
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _endDate ?? (_startDate ?? DateTime.now()),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            _endDate = picked;
                          });
                          setState(() {
                            _endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _endDate != null
                                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                  : 'Select End Date',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _endDate != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.textSecondary,
                              size: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskList() {
    if (_isLoadingTasks) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
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
              'Loading tasks...',
              style: AppTypography.bodyLarge.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Container(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_outlined,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 64,
                  tablet: 80,
                  desktop: 96,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                'No tasks found',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 12,
                  desktop: 16,
                ),
              ),
              Text(
                'Total: $_totalTasks | Search: "$_searchQuery" | Status: "$_selectedStatus"${_selectedStatus == 'survey' ? ' (Sub Cat: 1)' : ''} | Filters: ${_getFilterCount()}',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 14,
                  ),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Use tasks directly since search is now handled server-side
    List<TaskModel> filteredTasks = _tasks;

    return Container(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task count header
          Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Search Results (${filteredTasks.length} tasks)'
                  : 'Tasks (${filteredTasks.length}/${_totalTasks})',
              style: AppTypography.titleMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Task list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                FocusScope.of(context).unfocus(); // Dismiss keyboard
                // Reset pagination and reload tasks
                setState(() {
                  _currentPage = 1;
                  _hasMorePages = true;
                });
                await _loadTasks();
              },
              color: AppColors.primaryColor,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredTasks.length + (_hasMorePages ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end for pagination
                  if (index == filteredTasks.length) {
                    if (_isLoadingMore) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    } else if (_hasMorePages) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Scroll to load more',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }

                  final task = filteredTasks[index];
                  return TaskCard(
                    key: ValueKey('task_${task.id}_${task.progress}'),
                    task: task,
                    onTap: () {
                      FocusScope.of(context).unfocus(); // Dismiss keyboard
                      // TODO: Navigate to task detail screen
                      print('Task tapped: ${task.name}');
                    },
                    onTaskUpdated: (updatedTask) {
                      // Update the task in the local list
                      setState(() {
                        final index = _tasks.indexWhere(
                          (t) => t.id == updatedTask.id,
                        );
                        if (index != -1) {
                          _tasks[index] = updatedTask;
                        }
                      });
                    },
                    onTaskDeleted: (deletedTaskId) {
                      // Remove the deleted task from the local list
                      setState(() {
                        _tasks.removeWhere((t) => t.id == deletedTaskId);
                        _totalTasks = _totalTasks > 0 ? _totalTasks - 1 : 0;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
