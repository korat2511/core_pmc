import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../models/issue_model.dart';
import '../models/tag_model.dart';
import '../models/site_user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import 'add_issue_screen.dart';
import 'issue_detail_screen.dart';
import 'package:intl/intl.dart';

class IssuesScreen extends StatefulWidget {
  final SiteModel site;

  const IssuesScreen({
    super.key,
    required this.site,
  });

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  List<Issue> _issues = [];
  List<Issue> _filteredIssues = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedStatus; // null = all, 'Open', 'working', 'QC', 'solved', 'done'
  String? _selectedLinkType; // null = all, 'from_task', 'from_site', 'from_material', 'other'
  int? _selectedAssignedTo;
  int? _selectedTagId;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Filter options
  List<SiteUserModel> _siteUsers = [];
  List<TagModel> _tags = [];
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadIssues();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) return;

      // Load site users
      final usersResponse = await ApiService.getUsersBySite(
        apiToken: token,
        siteId: widget.site.id,
      );
      if (usersResponse.status == 1) {
        setState(() {
          _siteUsers = usersResponse.users;
        });
      }

      // Load tags
      final tagsResponse = await ApiService.getTags(apiToken: token);
      if (tagsResponse.status == 1) {
        setState(() {
          _tags = tagsResponse.data;
        });
      }
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  Future<void> _loadIssues({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.getIssues(
        apiToken: token,
        siteId: widget.site.id,
        status: _selectedStatus,
        linkType: _selectedLinkType,
        assignedTo: _selectedAssignedTo,
        tagId: _selectedTagId,
        search: _searchQuery.isNotEmpty ? _searchQuery : '',
        page: _currentPage,
        perPage: 20,
      );

      if (response.status == 1 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final issuesData = data['data'] as List<dynamic>?;
        
        final List<Issue> newIssues;
        if (issuesData != null) {
          newIssues = issuesData
              .where((e) => e is Map<String, dynamic>)
              .map((e) => Issue.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          newIssues = [];
        }

        setState(() {
          if (isRefresh || _currentPage == 1) {
            _issues = newIssues;
          } else {
            _issues.addAll(newIssues);
          }
          
          final pagination = data;
          if (pagination['current_page'] != null && pagination['last_page'] != null) {
            _hasMore = pagination['current_page'] < pagination['last_page'];
          } else {
            _hasMore = newIssues.length >= 20;
          }
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applySearchFilter();
        });
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message ?? 'Failed to load issues',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error loading issues: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreIssues() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadIssues();
  }

  Future<void> _refreshIssues() async {
    await _loadIssues(isRefresh: true);
  }

  void _applySearchFilter() {
    setState(() {
      _filteredIssues = List.from(_issues);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _refreshIssues();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedLinkType = null;
      _selectedAssignedTo = null;
      _selectedTagId = null;
      _showFilters = false;
    });
    _refreshIssues();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.errorColor;
      case 'working':
        return AppColors.warningColor;
      case 'qc':
        return AppColors.infoColor;
      case 'solved':
        return AppColors.successColor;
      case 'done':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getLinkTypeLabel(String linkType) {
    switch (linkType) {
      case 'from_task':
        return 'Task';
      case 'from_site':
        return 'Site';
      case 'from_material':
        return 'Material';
      case 'other':
        return 'Other';
      default:
        return linkType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Issues',
          showDrawer: false,
          showBackButton: true,
        ),
        body: Column(
          children: [
            // Search Bar and Filter Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(
                      hintText: 'Search issues...',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _showFilters
                            ? AppColors.primaryColor
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showFilters
                              ? AppColors.primaryColor
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                        color: _showFilters ? Colors.white : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filters
            if (_showFilters) _buildFilters(),

            // Issues List
            Expanded(
              child: _isLoading && _issues.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredIssues.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshIssues,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredIssues.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredIssues.length) {
                                return _buildLoadMoreButton();
                              }
                              return _buildIssueCard(_filteredIssues[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            NavigationUtils.push(
              context,
              AddIssueScreen(site: widget.site),
            ).then((_) => _refreshIssues());
          },
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('New Issue'),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatusFilter(),
              _buildLinkTypeFilter(),
              _buildAssignedToFilter(),
              _buildTagFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _selectedStatus != null
            ? AppColors.primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedStatus != null
              ? AppColors.primaryColor
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          hint: const Text('Status'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Status')),
            const DropdownMenuItem(value: 'Open', child: Text('Open')),
            const DropdownMenuItem(value: 'working', child: Text('Working')),
            const DropdownMenuItem(value: 'QC', child: Text('QC')),
            const DropdownMenuItem(value: 'solved', child: Text('Solved')),
            const DropdownMenuItem(value: 'done', child: Text('Done')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
            _refreshIssues();
          },
        ),
      ),
    );
  }

  Widget _buildLinkTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _selectedLinkType != null
            ? AppColors.primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedLinkType != null
              ? AppColors.primaryColor
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLinkType,
          hint: const Text('Source'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Sources')),
            const DropdownMenuItem(value: 'from_task', child: Text('Task')),
            const DropdownMenuItem(value: 'from_site', child: Text('Site')),
            const DropdownMenuItem(value: 'from_material', child: Text('Material')),
            const DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLinkType = value;
            });
            _refreshIssues();
          },
        ),
      ),
    );
  }

  Widget _buildAssignedToFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _selectedAssignedTo != null
            ? AppColors.primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedAssignedTo != null
              ? AppColors.primaryColor
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAssignedTo,
          hint: const Text('Assigned To'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Users')),
            ..._siteUsers.map((user) => DropdownMenuItem(
                  value: user.id,
                  child: Text(user.fullName),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAssignedTo = value;
            });
            _refreshIssues();
          },
        ),
      ),
    );
  }

  Widget _buildTagFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _selectedTagId != null
            ? AppColors.primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedTagId != null
              ? AppColors.primaryColor
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedTagId,
          hint: const Text('Tag'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Tags')),
            ..._tags.map((tag) => DropdownMenuItem(
                  value: tag.id,
                  child: Text(tag.name),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTagId = value;
            });
            _refreshIssues();
          },
        ),
      ),
    );
  }

  Widget _buildIssueCard(Issue issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          NavigationUtils.push(
            context,
            IssueDetailScreen(issueId: issue.id, site: widget.site),
          ).then((_) => _refreshIssues());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(issue.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.status,
                      style: AppTypography.bodySmall.copyWith(
                        color: _getStatusColor(issue.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getLinkTypeLabel(issue.linkType),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                issue.description,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (issue.assignedUser != null)
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          issue.assignedUser!['name'] ?? 'Unknown',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  if (issue.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(issue.dueDate!),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: _hasMore ? _loadMoreIssues : null,
          child: const Text('Load More'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bug_report_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No issues found',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new issue to get started',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

