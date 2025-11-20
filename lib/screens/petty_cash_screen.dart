import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../models/petty_cash_entry_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import 'add_petty_cash_entry_screen.dart';
import 'package:intl/intl.dart';

class PettyCashScreen extends StatefulWidget {
  final SiteModel site;

  const PettyCashScreen({
    super.key,
    required this.site,
  });

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  List<PettyCashEntryModel> _entries = [];
  List<PettyCashEntryModel> _filteredEntries = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedLedgerType; // null = all, 'spent', 'received'
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Summary data
  double _totalReceived = 0.0;
  double _totalSpent = 0.0;
  double _currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries({bool isRefresh = false}) async {
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

      final response = await ApiService.getPettyCashEntries(
        apiToken: token,
        siteId: widget.site.id,
        ledgerType: _selectedLedgerType,
        page: _currentPage,
        perPage: 20,
      );

      if (response.status == 1 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final entriesList = data['entries'];
        final List<PettyCashEntryModel> newEntries;
        
        if (entriesList is List) {
          newEntries = entriesList
              .where((e) => e is Map<String, dynamic>)
              .map((e) => PettyCashEntryModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          newEntries = [];
        }

        setState(() {
          if (isRefresh || _currentPage == 1) {
            _entries = newEntries;
          } else {
            _entries.addAll(newEntries);
          }
          final summary = data['summary'] as Map<String, dynamic>?;
          _totalReceived = (summary?['total_received'] ?? 0.0).toDouble();
          _totalSpent = (summary?['total_spent'] ?? 0.0).toDouble();
          _currentBalance = (summary?['current_balance'] ?? 0.0).toDouble();
          
          final pagination = data['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            _hasMore = pagination['current_page'] < pagination['last_page'];
          } else {
            _hasMore = false;
          }
        });
        // Apply filter after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applySearchFilter();
        });
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message ?? 'Failed to load entries',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error loading entries: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreEntries() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadEntries();
  }

  Future<void> _refreshEntries() async {
    await _loadEntries(isRefresh: true);
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredEntries = _entries;
      });
      return;
    }

    setState(() {
      _filteredEntries = _entries.where((entry) {
        final query = _searchQuery.toLowerCase();
        return (entry.remark?.toLowerCase().contains(query) ?? false) ||
            (entry.transactionId?.toLowerCase().contains(query) ?? false) ||
            (entry.paidToName?.toLowerCase().contains(query) ?? false) ||
            (entry.receivedFromName?.toLowerCase().contains(query) ?? false) ||
            entry.amount.toString().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteEntry(PettyCashEntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.deletePettyCashEntry(
        apiToken: token,
        entryId: entry.id,
      );

      if (response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: response.message ?? 'Entry deleted successfully',
        );
        _refreshEntries();
      } else {
        SnackBarUtils.showError(
          context,
          message: response.message ?? 'Failed to delete entry',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error deleting entry: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Petty Cash - ${widget.site.name}',
        showDrawer: false,
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(),
          
          // Filter and Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: CustomSearchBar(
                      hintText: 'Search entries...',
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        // Apply filter after the frame is built
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _applySearchFilter();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      value: _selectedLedgerType,
                      decoration: InputDecoration(
                        labelText: 'Filter',
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'spent',
                          child: Text('Spent'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'received',
                          child: Text('Received'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLedgerType = value;
                        });
                        // Refresh entries after the frame is built
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _refreshEntries();
                        });
                      },
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      icon: Icon(
                        Icons.filter_list,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Entries List
          Expanded(
            child: _isLoading && _entries.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshEntries,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEntries.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredEntries.length) {
                              // Load more trigger
                              if (!_isLoadingMore) {
                                _loadMoreEntries();
                              }
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildEntryCard(_filteredEntries[index]);
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
            AddPettyCashEntryScreen(site: widget.site),
          ).then((_) => _refreshEntries());
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Received',
              _totalReceived,
              Colors.green,
              Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Spent',
              _totalSpent,
              Colors.red,
              Icons.arrow_upward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Balance',
              _currentBalance,
              _currentBalance >= 0 ? Colors.blue : Colors.orange,
              Icons.account_balance_wallet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No petty cash entries found',
            style: AppTypography.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first entry to get started',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(PettyCashEntryModel entry) {
    final isReceived = entry.ledgerType == 'received';
    final color = isReceived ? Colors.green : Colors.red;
    final icon = isReceived ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          NavigationUtils.push(
            context,
            AddPettyCashEntryScreen(site: widget.site, entry: entry),
          ).then((_) => _refreshEntries());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReceived ? 'Received' : 'Spent',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '₹${entry.amount.toStringAsFixed(2)}',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        NavigationUtils.push(
                          context,
                          AddPettyCashEntryScreen(site: widget.site, entry: entry),
                        ).then((_) => _refreshEntries());
                      } else if (value == 'delete') {
                        _deleteEntry(entry);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isReceived && entry.receivedFromName != null)
                _buildInfoRow('From', entry.receivedFromName!),
              if (!isReceived && entry.paidToName != null)
                _buildInfoRow('To', entry.paidToName!),
              if (entry.remark != null && entry.remark!.isNotEmpty)
                _buildInfoRow('Remark', entry.remark!),
              _buildInfoRow(
                'Date',
                _formatDate(entry.entryDate),
              ),
              if (entry.transactionId != null && entry.transactionId!.isNotEmpty)
                _buildInfoRow('Transaction ID', entry.transactionId!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
