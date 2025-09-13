import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../models/task_detail_model.dart';
import '../models/task_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'select_materials_screen.dart';

class UpdateTaskScreen extends StatefulWidget {
  final TaskModel task;
  final Function(TaskModel)? onTaskUpdated;

  const UpdateTaskScreen({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  @override
  State<UpdateTaskScreen> createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  // Progress tracking
  bool _isUpdateProgress = true; // Default to "Update progress"
  
  // Check if this is a simple task (cat_sub_id 2,3,4,6)
  bool get _isSimpleTask => [2, 3, 4, 6].contains(_taskDetail?.catSubId);

  // Work input controllers
  final TextEditingController _workDoneTodayController =
      TextEditingController();
  final TextEditingController _workLeftController = TextEditingController();
  final TextEditingController _skilledWorkersController =
      TextEditingController();
  final TextEditingController _unskilledWorkersController =
      TextEditingController();

  // Media and notes controllers
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // State variables
  bool _isLoading = false;
  
  // Separate state for Update Progress mode
  List<File> _updateProgressImages = [];
  final TextEditingController _updateProgressRemarkController = TextEditingController();
  final TextEditingController _updateProgressInstructionsController = TextEditingController();
  final TextEditingController _updateProgressCommentsController = TextEditingController();
  
  // Separate state for No Progress mode
  List<File> _noProgressImages = [];
  final TextEditingController _noProgressRemarkController = TextEditingController();
  
  // Separate state for Simple Task mode (cat_sub_id 2,3,4,6)
  List<File> _simpleTaskImages = [];
  List<File> _simpleTaskAttachments = [];
  final TextEditingController _simpleTaskRemarkController = TextEditingController();
  
  // Material Used state
  bool _isMaterialUsed = false;
  List<Map<String, dynamic>> _selectedMaterials = [];
  List<Map<String, dynamic>> _availableMaterials = [];
  bool _isLoadingMaterials = false;
  
  bool _isUploadingImages = false;
  bool _isUploadingAttachments = false;

  // Progress slider
  double _progressValue = 0.0;
  
  // Validation error message
  String? _validationError;
  
  // Task detail data
  TaskDetailModel? _taskDetail;
  bool _isLoadingTaskDetail = true;

  @override
  void initState() {
    super.initState();
    _loadTaskDetail();
    _loadMaterials();
  }

  @override
  void dispose() {
    _workDoneTodayController.dispose();
    _workLeftController.dispose();
    _skilledWorkersController.dispose();
    _unskilledWorkersController.dispose();
    
    // Dispose Update Progress controllers
    _updateProgressRemarkController.dispose();
    _updateProgressInstructionsController.dispose();
    _updateProgressCommentsController.dispose();
    
    // Dispose No Progress controllers
    _noProgressRemarkController.dispose();
    
    // Dispose Simple Task controllers
    _simpleTaskRemarkController.dispose();
    
    super.dispose();
  }

    Future<void> _loadTaskDetail() async {
    setState(() {
      _isLoadingTaskDetail = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final taskDetail = await ApiService.getTaskDetail(
        apiToken: apiToken,
        taskId: widget.task.id,
      );

      setState(() {
        _taskDetail = taskDetail;
        _isLoadingTaskDetail = false;
      });

      // Initialize data after loading task detail
      _initializeData();
    } catch (e) {
      setState(() {
        _isLoadingTaskDetail = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to load task details: $e',
      );
    }
  }

  void _initializeData() {
    if (_taskDetail == null) return;
    
    // Calculate current progress
    final totalWork = _taskDetail!.totalWork ?? 100;
    final totalWorkDone = _taskDetail!.totalWorkDone ?? 0;
    _progressValue = totalWork > 0 ? (totalWorkDone / totalWork) : 0.0;
 
    // Initialize work left
    final workLeft = totalWork - totalWorkDone;
    _workLeftController.text = workLeft.toString();
    
    // Initialize work done today as empty (not "0")
    _workDoneTodayController.text = '';
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoadingMaterials = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        return;
      }

      final response = await ApiService.getMaterials(page: 1);
      
      if (response != null && response.status == 1) {
        setState(() {
          _availableMaterials = response.data.map((material) => {
            'id': material.id,
            'name': material.name,
            'brand_name': material.brandName,
            'unit_of_measurement': material.unitOfMeasurement,
            'specification': material.specification,
            'sku': material.sku,
            'current_stock': material.currentStock ?? 0,
            'isSelected': false,
            'quantity': 0,
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading materials: $e');
    } finally {
      setState(() {
        _isLoadingMaterials = false;
      });
    }
  }

  // Get current total work and work done values
  int get _totalWork => _taskDetail?.totalWork ?? 100;
  int get _currentTotalWorkDone => _taskDetail?.totalWorkDone ?? 0;
  
  // Calculate work done today based on progress
  int get _workDoneToday {
    final newTotalWorkDone = (_totalWork * _progressValue).round();
    return newTotalWorkDone - _currentTotalWorkDone;
  }
  
  // Helper methods to get current mode's data
  List<File> get _currentImages {
    if (_isSimpleTask) return _simpleTaskImages;
    return _isUpdateProgress ? _updateProgressImages : _noProgressImages;
  }
  
  TextEditingController get _currentRemarkController {
    if (_isSimpleTask) return _simpleTaskRemarkController;
    return _isUpdateProgress ? _updateProgressRemarkController : _noProgressRemarkController;
  }
  
  TextEditingController get _currentInstructionsController => _updateProgressInstructionsController;
  TextEditingController get _currentCommentsController => _updateProgressCommentsController;
  
  // Update all fields based on new progress value
  void _updateProgressFromSlider(double newProgress) {
    // Calculate minimum progress based on current work done
    final currentProgress = _totalWork > 0 ? (_currentTotalWorkDone / _totalWork) : 0.0;
    
    // If user tries to slide below current progress, ignore the change
    if (newProgress < currentProgress) {
      return;
    }
    
    setState(() {
      _progressValue = newProgress.clamp(0.0, 1.0);
      
      // Calculate new work done today
      final newTotalWorkDone = (_totalWork * _progressValue).round();
      final workDoneToday = newTotalWorkDone - _currentTotalWorkDone;
      
      // Update work done today field - only if there's actual work done
      if (workDoneToday > 0) {
        _workDoneTodayController.text = workDoneToday.toString();
      } else {
        _workDoneTodayController.text = '';
      }
      
      // Update work left field
      final workLeft = _totalWork - newTotalWorkDone;
      _workLeftController.text = workLeft.toString();
    });
  }
  
  // Update progress from work done today input
  void _updateProgressFromWorkDone(String value) {
    // Remove any non-digit characters except for the first minus sign
    String cleanValue = value.replaceAll(RegExp(r'[^\d-]'), '');
    
    // If the value starts with minus, remove it and set to empty
    if (cleanValue.startsWith('-')) {
      _workDoneTodayController.text = '';
      return;
    }
    
    // If empty, don't set to 0, keep it empty
    if (cleanValue.isEmpty) {
      setState(() {
        // Reset progress to current progress when field is empty
        final currentProgress = _totalWork > 0 ? (_currentTotalWorkDone / _totalWork) : 0.0;
        _progressValue = currentProgress;
        
        // Update work left
        final workLeft = _totalWork - _currentTotalWorkDone;
        _workLeftController.text = workLeft.toString();
      });
      return;
    }
    
    final workDoneToday = int.tryParse(cleanValue) ?? 0;
    
    // Ensure work done today is not negative
    if (workDoneToday < 0) {
      _workDoneTodayController.text = '';
      return;
    }
    
    // Calculate new total work done
    final newTotalWorkDone = _currentTotalWorkDone + workDoneToday;
    
    // Ensure total work done doesn't exceed total work
    if (newTotalWorkDone > _totalWork) {
      final maxWorkDoneToday = _totalWork - _currentTotalWorkDone;
      _workDoneTodayController.text = maxWorkDoneToday.toString();
      return;
    }
    
    setState(() {
      // Update progress value - ensure it doesn't go below current progress
      final currentProgress = _totalWork > 0 ? (_currentTotalWorkDone / _totalWork) : 0.0;
      final newProgress = _totalWork > 0 ? (newTotalWorkDone / _totalWork) : 0.0;
      _progressValue = newProgress.clamp(currentProgress, 1.0);
      
      // Update work left
      final workLeft = _totalWork - newTotalWorkDone;
      _workLeftController.text = workLeft.toString();
    });
  }

    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.task.name,
          showBackButton: true,
          showDrawer: false,
         
        ),
        body: _isLoadingTaskDetail
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              )
            : _taskDetail == null
                ? Center(
                    child: Text(
                      'Failed to load task details',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Type Selection (only for normal tasks)
              if (!_isSimpleTask) ...[
                _buildProgressTypeSelection(),
                SizedBox(height: 24),
              ],
   
                          // Content based on task type and selected mode
            if (_isSimpleTask) ...[
              // Simple Task Design (cat_sub_id 2,3,4,6)
              _buildSimpleTaskSection(),
            ] else ...[
              // Normal Task Design (cat_sub_id 5)
              if (_isUpdateProgress) ...[
                // Update Progress Mode
                _buildTotalWorkDoneDisplay(),
                SizedBox(height: 16),
                _buildProgressSlider(),
                SizedBox(height: 10),
                _buildWorkInputFields(),
                SizedBox(height: 10),
                _buildMaterialUsedSection(),
                SizedBox(height: 10),
                _buildMediaAndNotesSection(),
              ] else ...[
                // No Progress Mode
                _buildNoProgressSection(),
              ],
            ],
            SizedBox(height: 32),
   
            // Validation Error Display
            if (_validationError != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorColor),
                ),
                child: Text(
                  _validationError!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
   
            // Save Button
            _buildSaveButton(),
            SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isUpdateProgress = true;
                  _validationError = null; // Clear error when switching tabs
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isUpdateProgress
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Update progress',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isUpdateProgress
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isUpdateProgress = false;
                  _validationError = null; // Clear error when switching tabs
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !_isUpdateProgress
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No Progress',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: !_isUpdateProgress
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildTotalWorkDoneDisplay() {
    final totalWork = _totalWork;
    final currentTotalWorkDone = _currentTotalWorkDone;
    final newTotalWorkDone = (totalWork * _progressValue).round();
    final unit = _taskDetail?.unit ?? '%';
 
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Work Done',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '$newTotalWorkDone/$totalWork $unit',
            style: AppTypography.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(_progressValue * 100).toInt()}%',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryColor,
            inactiveTrackColor: AppColors.borderColor,
            thumbColor: AppColors.primaryColor,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
            trackHeight: 4,
          ),
                     child: Slider(
             value: _progressValue,
             min: 0.0,
             max: 1.0,
             divisions: 100,
             onChanged: (value) {
               _updateProgressFromSlider(value);
             },
           ),
        ),
      ],
    );
  }

  Widget _buildWorkInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Details',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),

        // Work Done Today and Work Left
        Row(
          children: [
                         Expanded(
               child: CustomTextField(
                 controller: _workDoneTodayController,
                 label: 'Work Done Today',
                 hintText: '0',
                 keyboardType: TextInputType.number,
                 onChanged: _updateProgressFromWorkDone,
               ),
             ),
            SizedBox(width: 16),
                         Expanded(
               child: CustomTextField(
                 controller: _workLeftController,
                 label: 'Work Left',
                 hintText: '0',
                 keyboardType: TextInputType.number,
                 enabled: false, // Read-only, calculated automatically
                 readOnly: true, // Make it clearly read-only
               ),
             ),
          ],
        ),
        SizedBox(height: 16),

        // Skilled and Unskilled Workers
        Row(
          children: [
                         Expanded(
               child: CustomTextField(
                 controller: _skilledWorkersController,
                 label: 'Skilled workers',
                 hintText: '0',
                 keyboardType: TextInputType.number,
                 onChanged: (value) {
                   // Remove any non-digit characters except for the first minus sign
                   String cleanValue = value.replaceAll(RegExp(r'[^\d-]'), '');
                   
                   // If the value starts with minus, remove it and set to 0
                   if (cleanValue.startsWith('-')) {
                     _skilledWorkersController.text = '0';
                     _skilledWorkersController.selection = TextSelection.fromPosition(
                       TextPosition(offset: 1),
                     );
                     return;
                   }
                   
                   // If empty, set to 0
                   if (cleanValue.isEmpty) {
                     _skilledWorkersController.text = '0';
                     return;
                   }
                   
                   final workers = int.tryParse(cleanValue) ?? 0;
                   if (workers < 0) {
                     _skilledWorkersController.text = '0';
                   }
                 },
               ),
             ),
             SizedBox(width: 16),
             Expanded(
               child: CustomTextField(
                 controller: _unskilledWorkersController,
                 label: 'Unskilled workers',
                 hintText: '0',
                 keyboardType: TextInputType.number,
                 onChanged: (value) {
                   // Remove any non-digit characters except for the first minus sign
                   String cleanValue = value.replaceAll(RegExp(r'[^\d-]'), '');
                   
                   // If the value starts with minus, remove it and set to 0
                   if (cleanValue.startsWith('-')) {
                     _unskilledWorkersController.text = '0';
                     _unskilledWorkersController.selection = TextSelection.fromPosition(
                       TextPosition(offset: 1),
                     );
                     return;
                   }
                   
                   // If empty, set to 0
                   if (cleanValue.isEmpty) {
                     _unskilledWorkersController.text = '0';
                     return;
                   }
                   
                   final workers = int.tryParse(cleanValue) ?? 0;
                   if (workers < 0) {
                     _unskilledWorkersController.text = '0';
                   }
                 },
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos Section (Optional)
        Text(
          'Add Photos (Optional)',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16),

        // Add Photos Button
        GestureDetector(
          onTap: _isUploadingImages ? null : _pickImages,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _isUploadingImages
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.add, color: AppColors.primaryColor, size: 32),
          ),
        ),
        
        // Show selected images count and previews
        if (_noProgressImages.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            '${_noProgressImages.length} photo(s) selected',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          // Image previews
          Container(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _noProgressImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _noProgressImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.borderColor,
                                child: Icon(
                                  Icons.error,
                                  color: AppColors.errorColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _noProgressImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textWhite,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        
        SizedBox(height: 32),

        // Remark Section (Compulsory)
        Text(
          'Add Remark *',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),

        // Remark Button
        GestureDetector(
          onTap: () {
            _showAddDataModal('remark', 'Remark');
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _noProgressRemarkController.text.trim().isNotEmpty 
                    ? AppColors.successColor
                    : AppColors.borderColor,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: _noProgressRemarkController.text.trim().isNotEmpty 
                      ? AppColors.successColor
                      : AppColors.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _noProgressRemarkController.text.trim().isNotEmpty 
                        ? _noProgressRemarkController.text
                        : 'Add remark explaining why there is no progress...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _noProgressRemarkController.text.trim().isNotEmpty 
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _noProgressRemarkController.text.trim().isNotEmpty 
                      ? Icons.check_circle
                      : Icons.add,
                  color: _noProgressRemarkController.text.trim().isNotEmpty 
                      ? AppColors.successColor
                      : AppColors.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaAndNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Photos',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),

        // Add Photos Button
        GestureDetector(
          onTap: _isUploadingImages ? null : _pickImages,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _isUploadingImages
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.add, color: AppColors.primaryColor, size: 32),
          ),
        ),
        
        // Show selected images count and previews
        if (_updateProgressImages.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            '${_updateProgressImages.length} photo(s) selected',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          // Image previews
          Container(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _updateProgressImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _updateProgressImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.borderColor,
                                child: Icon(
                                  Icons.error,
                                  color: AppColors.errorColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _updateProgressImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textWhite,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        
        SizedBox(height: 24),

        // Media Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildMediaActionButton(
                icon: Icons.mic,
                label: 'Voice Notes',
                onTap: () {
                  // TODO: Handle voice notes
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMediaActionButton(
                icon: Icons.edit_note,
                label: 'Remark',
                onTap: () {
                  _showAddDataModal('remark', 'Remark');
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMediaActionButton(
                icon: Icons.assignment,
                label: 'Instructions',
                onTap: () {
                  _showAddDataModal('instruction', 'Instruction');
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMediaActionButton(
                icon: Icons.comment,
                label: 'Comments',
                onTap: () {
                  _showAddDataModal('comment', 'Comment');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialUsedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Material Used Checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Is Material Used?',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Checkbox(
              value: _isMaterialUsed,
              onChanged: (value) {
                setState(() {
                  _isMaterialUsed = value ?? false;
                  if (!_isMaterialUsed) {
                    _selectedMaterials.clear();
                  }
                });
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
        
        if (_isMaterialUsed) ...[
          SizedBox(height: 16),
          
          // Material Selection Button
          GestureDetector(
            onTap: () async {
              final result = await NavigationUtils.push(
                context,
                SelectMaterialsScreen(
                  preSelectedMaterials: _selectedMaterials.isNotEmpty ? _selectedMaterials : null,
                ),
              );
              
              if (result != null && result is List) {
                setState(() {
                  _selectedMaterials = List<Map<String, dynamic>>.from(result);
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedMaterials.isNotEmpty ? AppColors.successColor : AppColors.borderColor,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: _selectedMaterials.isNotEmpty ? AppColors.successColor : AppColors.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Materials',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_selectedMaterials.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            '${_selectedMaterials.length} material(s) selected',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _buildMaterialSummary(),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _selectedMaterials.isNotEmpty ? Icons.check_circle : Icons.arrow_forward_ios,
                    color: _selectedMaterials.isNotEmpty ? AppColors.successColor : AppColors.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _updateSelectedMaterials() {
    _selectedMaterials = _availableMaterials
        .where((material) => material['isSelected'] as bool)
        .map((material) => {
              'id': material['id'],
              'name': material['name'],
              'brand_name': material['brand_name'],
              'unit_of_measurement': material['unit_of_measurement'],
              'quantity': material['quantity'],
            })
        .toList();
  }



  List<Map<String, dynamic>>? _buildUsedMaterials() {
    if (!_isMaterialUsed || _selectedMaterials.isEmpty) {
      return null;
    }
    
    return _selectedMaterials.map((material) => {
      'material_id': material['id'],
      'quantity': material['quantity'],
    }).toList();
  }

  String _buildMaterialSummary() {
    if (_selectedMaterials.isEmpty) return '';
    
    final summaries = _selectedMaterials.map((material) {
      final name = material['name'] ?? '';
      final quantity = material['quantity'] ?? 0;
      final unit = material['unit_of_measurement'] ?? '';
      return '$name: $quantity $unit';
    }).toList();
    
    return summaries.join(', ');
  }

  Widget _buildMediaActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: _isLoading ? null : _saveUpdate,
        text: _isLoading ? 'Saving...' : (_isSimpleTask ? 'Save Task' : 'Save Update'),
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildSimpleTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images Section
        Text(
          'Images',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),

        // Add Images Button
        GestureDetector(
          onTap: _isUploadingImages ? null : _pickImages,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _isUploadingImages
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.add_photo_alternate, color: AppColors.primaryColor, size: 32),
          ),
        ),
        
        // Show selected images count and previews
        if (_simpleTaskImages.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            '${_simpleTaskImages.length} image(s) selected',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          // Image previews
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _simpleTaskImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _simpleTaskImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.borderColor,
                                child: Icon(
                                  Icons.error,
                                  color: AppColors.errorColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _simpleTaskImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textWhite,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        
        SizedBox(height: 32),

        // Attachments Section
        Text(
          'Attachments',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),

        // Add Attachments Button
        GestureDetector(
          onTap: _isUploadingAttachments ? null : _pickAttachments,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _isUploadingAttachments
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.attach_file, color: AppColors.primaryColor, size: 32),
          ),
        ),
        
        // Show selected attachments count and previews
        if (_simpleTaskAttachments.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            '${_simpleTaskAttachments.length} attachment(s) selected',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          // Attachment previews
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _simpleTaskAttachments.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'File ${index + 1}',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _simpleTaskAttachments.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textWhite,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        
        SizedBox(height: 32),

        // Remarks Section
        Text(
          'Remarks',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),

        // Remarks Button
        GestureDetector(
          onTap: () {
            _showAddDataModal('remark', 'Remark');
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _simpleTaskRemarkController.text.trim().isNotEmpty 
                    ? AppColors.successColor
                    : AppColors.borderColor,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: _simpleTaskRemarkController.text.trim().isNotEmpty 
                      ? AppColors.successColor
                      : AppColors.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _simpleTaskRemarkController.text.trim().isNotEmpty 
                        ? _simpleTaskRemarkController.text
                        : 'Add remarks...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _simpleTaskRemarkController.text.trim().isNotEmpty 
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _simpleTaskRemarkController.text.trim().isNotEmpty 
                      ? Icons.check_circle
                      : Icons.add,
                  color: _simpleTaskRemarkController.text.trim().isNotEmpty 
                      ? AppColors.successColor
                      : AppColors.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final List<File> images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: true,
      maxImages: 10,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        if (_isSimpleTask) {
          _simpleTaskImages.addAll(images);
        } else if (_isUpdateProgress) {
          _updateProgressImages.addAll(images);
        } else {
          _noProgressImages.addAll(images);
        }
      });
    }
  }

  Future<void> _pickAttachments() async {
    final List<File> attachments = await ImagePickerUtils.pickDocumentsWithSource(
      context: context,
      maxFiles: 10,
              allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'rtf', 'dwg'],
    );

    if (attachments.isNotEmpty) {
      setState(() {
        _simpleTaskAttachments.addAll(attachments);
      });
    }
  }

  void _showAddDataModal(String type, String title) {
    TextEditingController controller;
    switch (type) {
      case 'remark':
        controller = _currentRemarkController;
        break;
      case 'instruction':
        controller = _currentInstructionsController;
        break;
      case 'comment':
        controller = _currentCommentsController;
        break;
      default:
        controller = _currentRemarkController;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Add $title',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Text Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your $title...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                onChanged: (value) {
                  // Trigger rebuild to update remark status display
                  setState(() {});
                },
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUpdate() async {
    // Clear previous validation error
    setState(() {
      _validationError = null;
    });

    // Validate based on task type
    if (_isSimpleTask) {
      // Simple tasks don't require validation - all fields are optional
      // Just proceed with saving
    } else {
      // Validate based on progress type for normal tasks
      if (_isUpdateProgress) {
        // Validate for "Update progress" mode
        final workDoneToday = int.tryParse(_workDoneTodayController.text) ?? 0;
        if (workDoneToday == 0) {
          setState(() {
            _validationError = 'You added work done 0. Please try to add "No Progress" instead.';
          });
          return;
        }
      } else {
        // Validate for "No Progress" mode - only check remark (photos are optional)
        if (_noProgressRemarkController.text.trim().isEmpty) {
          setState(() {
            _validationError = 'Please add a remark explaining why there is no progress.';
          });
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      ApiResponse? response;

      if (_isSimpleTask) {
        // Simple task update (decision, drawing, selection, quotation)
        response = await ApiService.updateSimpleTask(
          apiToken: apiToken,
          taskId: widget.task.id,
          remark: _simpleTaskRemarkController.text.trim().isNotEmpty 
              ? _simpleTaskRemarkController.text.trim() 
              : null,
          images: _simpleTaskImages,
          attachments: _simpleTaskAttachments,
        );
      } else {
        // Normal task update
        if (_isUpdateProgress) {
          // Update progress mode
          final workDoneToday = int.tryParse(_workDoneTodayController.text) ?? 0;
          final workLeft = int.tryParse(_workLeftController.text) ?? 0;
          final skilledWorkers = int.tryParse(_skilledWorkersController.text) ?? 0;
          final unskilledWorkers = int.tryParse(_unskilledWorkersController.text) ?? 0;

          final usedMaterials = _buildUsedMaterials();
          print('=== USED MATERIALS BEING SENT ===');
          print('Used Materials: $usedMaterials');
          
          response = await ApiService.updateTaskProgress(
            apiToken: apiToken,
            taskId: widget.task.id,
            workDone: workDoneToday.toString(),
            workLeft: workLeft.toString(),
            skillWorkers: skilledWorkers.toString(),
            unskilledWorkers: unskilledWorkers.toString(),
            remark:_updateProgressRemarkController.text.trim().isNotEmpty
                ? _updateProgressRemarkController.text.trim()
                : null,
            comment: _updateProgressCommentsController.text.trim().isNotEmpty
                ? _updateProgressCommentsController.text.trim() 
                : null,
            instruction: _updateProgressInstructionsController.text.trim().isNotEmpty 
                ? _updateProgressInstructionsController.text.trim() 
                : null,
            images: _updateProgressImages,
            usedMaterials: usedMaterials,
          );
        } else {
          // No progress mode
          final workLeft = int.tryParse(_workLeftController.text) ?? 0;

          response = await ApiService.updateTaskProgress(
            apiToken: apiToken,
            taskId: widget.task.id,
            workDone: "0",
            workLeft: workLeft.toString(),
            skillWorkers: "0",
            unskilledWorkers: "0",
            remark: _noProgressRemarkController.text.trim(),
            images: _noProgressImages,
          );
        }
      }

      if (response != null && response.status == 1) {
        // Update the parent screen with the new progress
        if (widget.onTaskUpdated != null) {
          final updatedTask = widget.task.copyWith(
            progress: (_progressValue * 100).round(),
          );
          print('=== UPDATE TASK SCREEN SENDING DATA ===');
          print('Task ID: ${updatedTask.id}');
          print('Task Name: ${updatedTask.name}');
          print('New Progress: ${updatedTask.progress}%');
          print('Assign Count: ${updatedTask.assign.length}');
          widget.onTaskUpdated!(updatedTask);
        }

        // Navigate back to refresh the task details
        Navigator.pop(context, 'Task updated successfully'); // Pass static success message
      } else {
        SnackBarUtils.showError(
          context, 
          message: response?.message ?? 'Failed to update task'
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to update task: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
