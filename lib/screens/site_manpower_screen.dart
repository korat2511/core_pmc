import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';
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
import '../widgets/custom_app_bar.dart';
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
  String whatsappMessage = "";
  bool _isLoading = false;
  Map<int, TextEditingController> _skilledControllers = {};
  Map<int, TextEditingController> _unskilledControllers = {};

  @override
  void initState() {
    super.initState();
    _loadManpowerForDate(_selectedDate);
  }

  @override
  void dispose() {
    // Dispose all controllers
    _skilledControllers.values.forEach((controller) => controller.dispose());
    _unskilledControllers.values.forEach((controller) => controller.dispose());
    
    // Clear the maps
    _skilledControllers.clear();
    _unskilledControllers.clear();
    
    super.dispose();
  }

  @override
  void deactivate() {
    // Close keyboard when leaving the screen
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
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
          whatsappMessage = _manpowerService.whatsAppMessage;
          
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
      categoryName: manpower.category.name,
      shift: manpower.shift,
      skilledWorker: manpower.skilledWorker,
      unskilledWorker: manpower.unskilledWorker,
    )).toList();
    
    _originalEntries = _entries.map((entry) => entry.copyWith()).toList();
    
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

  void _addNewEntry() async {
    // Show category picker first
    final selectedCategory = await _showCategoryPickerForNewEntry();
    
    if (selectedCategory != null) {
      final newIndex = _entries.length;
      setState(() {
        _entries.add(ManpowerEntryModel(
          categoryId: selectedCategory.id,
          categoryName: selectedCategory.name,
          shift: 1,
          skilledWorker: 0,
          unskilledWorker: 0,
        ));
        _skilledControllers[newIndex] = TextEditingController(text: '0');
        _unskilledControllers[newIndex] = TextEditingController(text: '0');
      });
    }
  }

  Future<CategoryModel?> _showCategoryPickerForNewEntry() async {
    final excludedCategoryIds = _entries
        .where((entry) => entry.categoryId != 0)
        .map((entry) => entry.categoryId)
        .toList();

    return await CategoryPickerUtils.showCategoryPicker(
      context: context,
      siteId: widget.site.id,
      allowedSubIds: [5],
      excludedCategoryIds: excludedCategoryIds,
    );
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
        whatsappMessage = _manpowerService.whatsAppMessage;
        SnackBarUtils.showSuccess(
          context,
          message: 'Manpower saved successfully',
        );
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

  void _shareWhatsAppMessage() async{
    if (whatsappMessage.isNotEmpty) {
      await SocialSharingPlus.shareToSocialMedia(
        SocialPlatform.whatsapp,
        whatsappMessage,
        isOpenBrowser: true,
      );
    }else{
      SnackBarUtils.showInfo(
        context,
        message: 'Manpower data not found...!',
      );
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
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 12),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
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
      return today.subtract(Duration(days: 29 - index));
    });

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: dates.length,
      controller: ScrollController(initialScrollOffset: 29 * 78.0),
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
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
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
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
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
                        size: 60,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No manpower entries',
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap "Add Manpower" to get started',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
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

        // Action Buttons - Compact Layout
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Row with Add and WhatsApp buttons
              Row(
                children: [
                  // Add Entry Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addNewEntry,
                      icon: Icon(Icons.add, color: Colors.white, size: 16),
                      label: Text(
                        'Add',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // WhatsApp Share Button (only show if there's a message)
                  if (whatsappMessage.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareWhatsAppMessage,
                        icon: Icon(Icons.share, color: Colors.white, size: 16),
                        label: Text(
                          'WhatsApp',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Save Button - Full width but smaller
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveManpower,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 1,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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

  Widget _buildEntryCard(int index) {
    final entry = _entries[index];
    String categoryName = 'Select Category';
    
    if (entry.categoryId != 0) {
      categoryName = entry.categoryName ?? 'Category ID: ${entry.categoryId}';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Category Name and Delete Icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: entry.categoryId == 0 ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                // Delete icon for all entries
                GestureDetector(
                  onTap: () => _removeEntry(index),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Shift Selection (Dropdown) and Worker Inputs
            Row(
              children: [
                // Shift Dropdown
                Expanded(
                  flex: 2,
                  child: _buildShiftDropdown(index),
                ),
                SizedBox(width: 12),
                // Skilled Workers
                Expanded(
                  flex: 1,
                  child: _buildWorkerInput(
                    'Skilled',
                    _skilledControllers[index] ?? TextEditingController(text: entry.skilledWorker.toString()),
                    (value) {
                      final newEntry = entry.copyWith(
                        skilledWorker: int.tryParse(value) ?? 0,
                      );
                      _updateEntry(index, newEntry);
                    },
                  ),
                ),
                SizedBox(width: 12),
                // Unskilled Workers
                Expanded(
                  flex: 1,
                  child: _buildWorkerInput(
                    'Unskilled',
                    _unskilledControllers[index] ?? TextEditingController(text: entry.unskilledWorker.toString()),
                    (value) {
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

  Widget _buildShiftDropdown(int index) {
    final entry = _entries[index];
    final shiftOptions = [
      {'value': 1, 'label': 'Day', 'icon': Icons.wb_sunny},
      {'value': 2, 'label': 'Night', 'icon': Icons.nightlight},
      {'value': 3, 'label': 'Day Night', 'icon': Icons.schedule},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shift',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: entry.shift,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              items: shiftOptions.map((option) {
                return DropdownMenuItem<int>(
                  value: option['value'] as int,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          color: AppColors.primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(option['label'] as String),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final newEntry = entry.copyWith(shift: value);
                  _updateEntry(index, newEntry);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerInput(String label, TextEditingController controller, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              hintText: '0',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 16,
              ),
              counterText: '', // Remove character counter
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

