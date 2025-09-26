import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/petty_cash_entry_model.dart';
import '../models/site_model.dart';
import '../services/petty_cash_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import 'add_petty_cash_entry_screen.dart';

// Utility function for currency formatting - always use abbreviations
String formatCurrency(double amount) {
  if (amount >= 10000000) {
    return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
  } else if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(1)}L';
  } else if (amount >= 1000) {
    return '₹${(amount / 1000).toStringAsFixed(1)}K';
  } else {
    return '₹${amount.toStringAsFixed(0)}';
  }
}

// Utility function for currency formatting without ₹ symbol
String formatCurrencyWithoutSymbol(double amount) {
  if (amount >= 10000000) {
    return '${(amount / 10000000).toStringAsFixed(1)}Cr';
  } else if (amount >= 100000) {
    return '${(amount / 100000).toStringAsFixed(1)}L';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)}K';
  } else {
    return '${amount.toStringAsFixed(0)}';
  }
}

class PettyCashScreen extends StatefulWidget {
  final SiteModel site;

  const PettyCashScreen({super.key, required this.site});

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  List<PettyCashEntry> _entries = [];
  PettyCashBalance _balance = PettyCashBalance(
    siteId: '',
    siteName: '',
    totalReceived: 0.0,
    totalSpent: 0.0,
    currentBalance: 0.0,
    lastUpdated: DateTime.now(),
  );
  bool _isLoading = true;
  bool _showChart = false;
  String _selectedFilter = 'all'; // all, received, spent
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await PettyCashService.getPettyCashEntries(
        siteId: widget.site.id.toString(),
        startDate: _startDate,
        endDate: _endDate,
      );

      final balance = await PettyCashService.getPettyCashBalance(widget.site.id.toString());

      setState(() {
        _entries = entries;
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(context, message: 'Failed to load data: $e');
    }
  }

  List<PettyCashEntry> get _filteredEntries {
    if (_selectedFilter == 'all') return _entries;
    return _entries.where((entry) => entry.ledgerType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'PETTY CASH LEDGER',
        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : Column(
              children: [
                // Balance Card
                _buildBalanceCard(),
                
                // Filter and Chart Toggle
                _buildFilterSection(),
                
                // Chart Section
                if (_showChart) _buildChartSection(),
                
                // Entries List
                Expanded(child: _buildEntriesList()),
              ],
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: CustomButton(
          text: 'Update Petty Cash',
          onPressed: _addEntry,
          backgroundColor: AppColors.primaryColor,
          textColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatCurrency(_balance.currentBalance),
                style: AppTypography.titleLarge.copyWith(
                  color: _balance.currentBalance.isNegative 
                      ? AppColors.errorColor 
                      : AppColors.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _balance.currentBalance.isNegative 
                      ? AppColors.errorColor.withOpacity(0.1)
                      : AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _balance.currentBalance.isNegative ? 'Deficit' : 'Surplus',
                  style: AppTypography.bodySmall.copyWith(
                    color: _balance.currentBalance.isNegative 
                        ? AppColors.errorColor 
                        : AppColors.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Received',
                  formatCurrency(_balance.totalReceived),
                  AppColors.successColor,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildBalanceItem(
                  'Spent',
                  formatCurrency(_balance.totalSpent),
                  AppColors.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String amount, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 3),
          Text(
            amount,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Filter Dropdown
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All Entries')),
                    DropdownMenuItem(value: 'received', child: Text('Received')),
                    DropdownMenuItem(value: 'spent', child: Text('Spent')),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Chart Toggle
          IconButton(
            onPressed: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
            icon: Icon(
              _showChart ? Icons.table_chart : Icons.bar_chart,
              color: AppColors.primaryColor,
            ),
            tooltip: _showChart ? 'Hide Chart' : 'Show Chart',
          ),
          // Date Filter
          IconButton(
            onPressed: _showDateFilter,
            icon: Icon(
              Icons.date_range,
              color: AppColors.primaryColor,
            ),
            tooltip: 'Filter by Date',
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 200,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _entries.isEmpty
          ? Center(
              child: Text(
                'No data available for chart',
                style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _entries.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.ledgerType == 'received' 
                            ? entry.value.amount 
                            : -entry.value.amount,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEntriesList() {
    final filteredEntries = _filteredEntries;

    if (filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No petty cash entries found',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first entry',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Ledger Header
        _buildLedgerHeader(),
        // Entries List
        Expanded(
          child: Builder(
            builder: (context) {
              // Sort entries by date (oldest first) for proper balance calculation
              final sortedEntries = List<PettyCashEntry>.from(filteredEntries);
              sortedEntries.sort((a, b) => a.entryDate.compareTo(b.entryDate));
              
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final runningBalance = _calculateRunningBalance(index, sortedEntries);
                  return _buildLedgerEntry(entry, runningBalance, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Entry',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Balance',
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildLedgerEntry(PettyCashEntry entry, double runningBalance, int index) {
    final isReceived = entry.ledgerType == 'received';
    final amountColor = isReceived ? AppColors.successColor : AppColors.errorColor;
    final backgroundColor = isReceived 
        ? AppColors.successColor.withOpacity(0.1)
        : AppColors.errorColor.withOpacity(0.1);
    
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: amountColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Entry Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  _getEntryDescription(entry),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.grey[700],
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Updated by ${_getUserDisplayName(entry)} on ${_formatDate(entry.entryDate)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isReceived ? '+' : '-'}${formatCurrencyWithoutSymbol(entry.amount)}',
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          // Running Balance
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency(runningBalance),
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                color: runningBalance.isNegative ? AppColors.errorColor : AppColors.successColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          // Transaction Amount

        ],
      ),
    );
  }

  String _getEntryDescription(PettyCashEntry entry) {
    if (entry.ledgerType == 'received') {
      return 'Via: ${_formatPaymentMethod(entry.receivedVia)} • From: ${_formatRecipientName(entry.receivedFrom)}';
    } else {
      // Use the proper name from the new fields if available
      String recipientName = entry.paidToName ?? entry.paidTo;
      if (entry.paidToType == 'other' && entry.otherRecipient != null) {
        recipientName = entry.otherRecipient!;
      }
      return 'Via: ${_formatPaymentMethod(entry.paidVia)} • To: ${_formatRecipientName(recipientName)}';
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'CASH';
      case 'bank_transfer':
        return 'BANK TRANSFER';
      case 'cheque':
        return 'CHEQUE';
      case 'upi':
        return 'UPI';
      case 'credit_card':
        return 'CREDIT CARD';
      case 'other':
        return 'OTHER';
      default:
        return method.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatRecipientName(String name) {
    if (name.isEmpty) return 'Unknown';
    
    // If it's a generic placeholder, show it as is
    if (name.toLowerCase().contains('vendor') || 
        name.toLowerCase().contains('agency') || 
        name.toLowerCase().contains('engineer') ||
        name.toLowerCase().contains('coordinator')) {
      return name;
    }
    
    // Otherwise, capitalize properly
    return name.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
    ).join(' ');
  }

  String _getUserDisplayName(PettyCashEntry entry) {
    if (entry.ledgerType == 'received') {
      return entry.receivedBy.isNotEmpty ? _formatRecipientName(entry.receivedBy) : 'Unknown';
    } else {
      return entry.paidBy.isNotEmpty ? _formatRecipientName(entry.paidBy) : 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hours = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minutes = date.minute.toString().padLeft(2, '0');
    
    return '${date.day} ${months[date.month - 1]}, ${date.year} $hours:$minutes $ampm';
  }

  double _calculateRunningBalance(int index, List<PettyCashEntry> entries) {
    double balance = 0.0; // Start from 0
    
    // Calculate balance up to and including this index
    // entries are already sorted by date (oldest first)
    for (int i = 0; i <= index; i++) {
      final entry = entries[i];
      if (entry.ledgerType == 'received') {
        balance += entry.amount;
      } else {
        balance -= entry.amount;
      }
    }
    
    return balance;
  }


  void _addEntry() {
    NavigationUtils.push(
      context,
      AddPettyCashEntryScreen(site: widget.site),
    ).then((_) {
      _loadData(); // Refresh data after adding entry
    });
  }

  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Start Date'),
              subtitle: Text(_startDate != null 
                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                  : 'Not selected'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: Text('End Date'),
              subtitle: Text(_endDate != null 
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : 'Not selected'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              _loadData();
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          CustomButton(
            text: 'Apply',
            onPressed: () {
              _loadData();
              Navigator.pop(context);
            },
            backgroundColor: AppColors.primaryColor,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
