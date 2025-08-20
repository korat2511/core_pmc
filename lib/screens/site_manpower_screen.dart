import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/category_picker_utils.dart';
import '../models/site_model.dart';
import '../models/manpower_model.dart';
import '../models/manpower_entry_model.dart';
import '../models/category_model.dart';
import '../services/manpower_service.dart';
import '../services/category_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dismiss_keyboard.dart';

class SiteManpowerScreen extends StatefulWidget {
  final SiteModel site;

  const SiteManpowerScreen({
    super.key,
    required this.site,
  });

  @override
  State<SiteManpowerScreen> createState() => _SiteManpowerScreenState();
}

class _SiteManpowerScreenState extends State<SiteManpowerScreen> {
  final ManpowerService _manpowerService = ManpowerService();
  
  DateTime _selectedDate = DateTime.now();
  List<ManpowerModel> _manpowerList = [];
  List<ManpowerEntryModel> _entries = [];
  List<ManpowerEntryModel> _originalEntries = []; // Track original data
  bool _isLoading = false;
  Map<int, TextEditingController> _skilledControllers = {};
  Map<int, TextEditingController> _unskilledControllers = {};

  @override
  void initState() {
    super.initState();
    _loadManpowerForDate(_selectedDate);
  }



  Future<void> _loadManpowerForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    final dateString = DateFormat('dd-MM-yyyy').format(date);
    final success = await _manpowerService.getManpowerByDate(
      siteId: widget.site.id,
      date: dateString,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _manpowerList = _manpowerService.manpowerList;
          _initializeEntries();
        }
      });

      if (!success) {
        SnackBarUtils.showError(
          context,
          message: _manpowerService.errorMessage,
        );
      }
    }
  }

  void _initializeEntries() {
    _entries = _manpowerList.map((manpower) => ManpowerEntryModel(
      categoryId: manpower.categoryId,
      categoryName: manpower.category.name, // Use the category name from the manpower model
      shift: manpower.shift,
      skilledWorker: manpower.skilledWorker,
      unskilledWorker: manpower.unskilledWorker,
    )).toList();
    
    // Store original entries for change detection
    _originalEntries = _entries.map((entry) => entry.copyWith()).toList();
    
    // Initialize controllers
    _skilledControllers.clear();
    _unskilledControllers.clear();
    for (int i = 0; i < _entries.length; i++) {
      _skilledControllers[i] = TextEditingController(text: _entries[i].skilledWorker.toString());
      _unskilledControllers[i] = TextEditingController(text: _entries[i].unskilledWorker.toString());
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadManpowerForDate(date);
  }

  void _addNewEntry() {
    final newIndex = _entries.length;
    setState(() {
      _entries.add(ManpowerEntryModel(
        categoryId: 0,
        shift: 1,
        skilledWorker: 0,
        unskilledWorker: 0,
      ));
      _skilledControllers[newIndex] = TextEditingController(text: '0');
      _unskilledControllers[newIndex] = TextEditingController(text: '0');
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _skilledControllers.remove(index);
      _unskilledControllers.remove(index);
      
      // Reindex controllers
      final newSkilledControllers = <int, TextEditingController>{};
      final newUnskilledControllers = <int, TextEditingController>{};
      
      for (int i = 0; i < _entries.length; i++) {
        newSkilledControllers[i] = _skilledControllers[i] ?? TextEditingController(text: _entries[i].skilledWorker.toString());
        newUnskilledControllers[i] = _unskilledControllers[i] ?? TextEditingController(text: _entries[i].unskilledWorker.toString());
      }
      
      _skilledControllers = newSkilledControllers;
      _unskilledControllers = newUnskilledControllers;
    });
  }

  void _updateEntry(int index, ManpowerEntryModel entry) {
    setState(() {
      _entries[index] = entry;
    });
  }

  bool _hasDataChanged() {
    if (_entries.length != _originalEntries.length) return true;
    
    for (int i = 0; i < _entries.length; i++) {
      final current = _entries[i];
      final original = _originalEntries[i];
      
      if (current.categoryId != original.categoryId ||
          current.shift != original.shift ||
          current.skilledWorker != original.skilledWorker ||
          current.unskilledWorker != original.unskilledWorker) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveManpower() async {
    // Check if data has changed
    if (!_hasDataChanged()) {
      SnackBarUtils.showInfo(
        context,
        message: 'Same manpower data',
      );
      return;
    }

    // Validate entries
    for (int i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (entry.categoryId == 0) {
        SnackBarUtils.showError(
          context,
          message: 'Please select a category for entry ${i + 1}',
        );
        return;
      }
      if (entry.skilledWorker == 0 && entry.unskilledWorker == 0) {
        SnackBarUtils.showError(
          context,
          message: 'Please add at least one worker for entry ${i + 1}',
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final dateString = DateFormat('dd-MM-yyyy').format(_selectedDate);
    final success = await _manpowerService.saveManpower(
      siteId: widget.site.id,
      date: dateString,
      entries: _entries,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Manpower saved successfully',
        );
        // Update original entries to reflect the saved state
        _originalEntries = _entries.map((entry) => entry.copyWith()).toList();
        _loadManpowerForDate(_selectedDate);
      } else {
        SnackBarUtils.showError(
          context,
          message: _manpowerService.errorMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manpower',
        showDrawer: false,
        showBackButton: true,
      ),
      body: DismissKeyboard(
        child: Column(
          children: [
            // Horizontal Date Picker
            Padding(
              padding: ResponsiveUtils.verticalPadding(context),
              child: Container(
                height: 80,
                padding: ResponsiveUtils.horizontalPadding(context),
                child: _buildHorizontalDatePicker(),
              ),
            ),

            // Current Date Display
            Padding(
              padding: ResponsiveUtils.horizontalPadding(context),
              child: Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                style: AppTypography.titleMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
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

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : _buildEditMode(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    final today = DateTime.now();
    final dates = List.generate(30, (index) {
      return today.subtract(Duration(days: 29 - index)); // Show last 30 days, newest first
    });

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: dates.length,
      controller: ScrollController(initialScrollOffset: 29 * 78.0), // Scroll to newest date (today)
      itemBuilder: (context, index) {
        final date = dates[index];
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        return GestureDetector(
          onTap: () => _onDateSelected(date),
          child: Container(
            width: 70,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor
                  : isToday
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(date),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  DateFormat('E').format(date),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  date.day.toString(),
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewMode() {
    if (_manpowerList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.engineering_outlined,
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
              'No manpower data for this date',
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
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ),
            ),
            Text(
              'Tap "Edit" to add manpower',
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadManpowerForDate(_selectedDate),
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: ResponsiveUtils.horizontalPadding(context),
        itemCount: _manpowerList.length,
        itemBuilder: (context, index) {
          final manpower = _manpowerList[index];
          return _buildManpowerCard(manpower, index);
        },
      ),
    );
  }

  Widget _buildEditMode() {
    return Column(
      children: [
        // Entries List
        Expanded(
          child: _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.engineering_outlined,
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
                        'No manpower entries',
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
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),
                      Text(
                        'Tap "Add Entry" to get started',
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
                )
              : ListView.builder(
                  padding: ResponsiveUtils.horizontalPadding(context),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    return _buildEntryCard(index);
                  },
                ),
        ),

        // Action Buttons
        Container(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            children: [
              // Add Entry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addNewEntry,
                  icon: Icon(
                    Icons.add,
                    color: AppColors.textWhite,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                  ),
                  label: Text(
                    'Add Manpower',
                    style: AppTypography.bodyMedium.copyWith(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor,
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
                ),
              ),
              
              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 12,
                  tablet: 16,
                  desktop: 20,
                ),
              ),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveManpower,
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
                  child: _isLoading
                      ? SizedBox(
                          width: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 24,
                            desktop: 28,
                          ),
                          height: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 24,
                            desktop: 28,
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                          ),
                        )
                      : Text(
                          'Save Manpower',
                          style: AppTypography.bodyLarge.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
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
      ],
    );
  }

  Widget _buildManpowerCard(ManpowerModel manpower, int index) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manpower.category.name,
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
                                mobile: 8,
                                tablet: 10,
                                desktop: 12,
                              ),
                              vertical: ResponsiveUtils.responsiveSpacing(
                                context,
                                mobile: 4,
                                tablet: 6,
                                desktop: 8,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.responsiveSpacing(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  desktop: 10,
                                ),
                              ),
                            ),
                            child: Text(
                              manpower.shiftText,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 10,
                                  tablet: 12,
                                  desktop: 14,
                                ),
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 10,
                              desktop: 12,
                            ),
                          ),
                          Text(
                            'ID: ${manpower.categoryId}',
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
              ],
            ),
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildWorkerInfo(
                    'Skilled Workers',
                    manpower.skilledWorker,
                    Icons.engineering,
                    AppColors.successColor,
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
                  child: _buildWorkerInfo(
                    'Unskilled Workers',
                    manpower.unskilledWorker,
                    Icons.people,
                    AppColors.warningColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerInfo(String title, int count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 8,
            tablet: 12,
            desktop: 16,
          ),
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
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
          Text(
            count.toString(),
            style: AppTypography.titleLarge.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 2,
              tablet: 4,
              desktop: 6,
            ),
          ),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 10,
                tablet: 12,
                desktop: 14,
              ),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(int index) {
    final entry = _entries[index];
    String categoryName = 'Select Category';
    
    // Show the actual category name if available, otherwise show ID
    if (entry.categoryId != 0) {
      categoryName = entry.categoryName ?? 'Category ID: ${entry.categoryId}';
    }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Category Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCategoryPicker(index),
                    child: Container(
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
                          mobile: 12,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite,
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
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: AppColors.textSecondary,
                            size: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 10,
                              desktop: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              categoryName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                                color: entry.categoryId == 0
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                            size: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10,),
                if (_entries.length > 1)
                  GestureDetector(
                    onTap: () => _removeEntry(index),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: AppColors.errorColor,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            
            // Shift Selection
            Row(
              children: [
                Expanded(
                  child: _buildShiftButton(
                    index,
                    1,
                    'Day',
                    Icons.wb_sunny,
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
                Expanded(
                  child: _buildShiftButton(
                    index,
                    2,
                    'Night',
                    Icons.nightlight,
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
                Expanded(
                  child: _buildShiftButton(
                    index,
                    3,
                    'Day Night',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            
            // Worker Counts
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _skilledControllers[index] ?? TextEditingController(text: entry.skilledWorker.toString()),
                    label: 'Skilled Workers',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icon(Icons.engineering),
                    onChanged: (value) {
                      final newEntry = entry.copyWith(
                        skilledWorker: int.tryParse(value) ?? 0,
                      );
                      _updateEntry(index, newEntry);
                    },
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
                  child: CustomTextField(
                    controller: _unskilledControllers[index] ?? TextEditingController(text: entry.unskilledWorker.toString()),
                    label: 'Unskilled Workers',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icon(Icons.people),
                    onChanged: (value) {
                      final newEntry = entry.copyWith(
                        unskilledWorker: int.tryParse(value) ?? 0,
                      );
                      _updateEntry(index, newEntry);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftButton(int index, int shift, String label, IconData icon) {
    final entry = _entries[index];
    final isSelected = entry.shift == shift;

    return GestureDetector(
      onTap: () {
        final newEntry = entry.copyWith(shift: shift);
        _updateEntry(index, newEntry);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 8,
            tablet: 12,
            desktop: 16,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryColor.withOpacity(0.1)
              : AppColors.textWhite,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryColor
                : AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 2,
                tablet: 4,
                desktop: 6,
              ),
            ),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
                color: isSelected 
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(int index) async {
    // Get list of already added category IDs to exclude them
    final excludedCategoryIds = _entries
        .where((entry) => entry.categoryId != 0)
        .map((entry) => entry.categoryId)
        .toList();

    final selectedCategory = await CategoryPickerUtils.showCategoryPicker(
      context: context,
      siteId: widget.site.id,
      allowedSubIds: [5], // Example: Only show categories with sub IDs 5, 6, 7
      excludedCategoryIds: excludedCategoryIds, // Exclude already added categories
    );
    
    if (selectedCategory != null) {
      final newEntry = _entries[index].copyWith(
        categoryId: selectedCategory.id,
        categoryName: selectedCategory.name, // Store the category name
      );
      _updateEntry(index, newEntry);
    }
  }
}
