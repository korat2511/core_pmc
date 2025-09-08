import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_colors.dart';

import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../core/utils/user_assignment_utils.dart';
import '../core/utils/category_picker_utils.dart';
import '../core/utils/qc_category_picker_utils.dart';
import '../core/utils/decision_pending_from_utils.dart';
import '../models/site_model.dart';
import '../models/category_model.dart';
import '../models/qc_category_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_picker_field.dart';

class CreateTaskScreen extends StatefulWidget {
  final SiteModel site;

  const CreateTaskScreen({
    super.key,
    required this.site,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  // Loading states
  bool _isLoading = false;

  // Selected category
  CategoryModel? _selectedCategory;

  // Form controllers for cat_sub_id 2,3,4,6
  final TextEditingController _categoryNameTitleController = TextEditingController();
  final TextEditingController _categoryNameRequiredByController = TextEditingController();
  final TextEditingController _askingDateController = TextEditingController();
  final TextEditingController _requirementDateController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  // Form controllers for cat_sub_id 5
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Selected values
  QcCategoryModel? _selectedQcCategory;
  List<UserModel> _selectedUsers = [];
  final List<File> _selectedImages = [];

  // Agency options for different cat_sub_id
  String? _selectedAgency;
  final TextEditingController _otherPendingByController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _categoryNameTitleController.dispose();
    _categoryNameRequiredByController.dispose();
    _otherPendingByController.dispose();
    _askingDateController.dispose();
    _requirementDateController.dispose();
    _remarkController.dispose();
    _commentsController.dispose();
    _instructionsController.dispose();
    _taskNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }



  bool get _isSimpleTask => _selectedCategory != null && [2, 3, 4, 6].contains(_selectedCategory!.catSubId);
  bool get _isNormalTask => _selectedCategory != null && _selectedCategory!.catSubId == 5;

  // Helper method to format agency display text
  String _getAgencyDisplayText() {
    if (_selectedAgency == null || _selectedAgency!.isEmpty) {
      return 'Select agency';
    }
    
    final agencies = _selectedAgency!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    if (agencies.isEmpty) {
      return 'Select agency';
    }
    
    if (agencies.length == 1) {
      return agencies.first;
    }
    
    if (agencies.length == 2) {
      return '${agencies.first} & ${agencies.last}';
    }
    
    return '${agencies.first} + ${agencies.length - 1} more';
  }

  // Helper methods
  Future<void> _showAgencySelectionModal() async {
    if (_selectedCategory == null) return;
    
    // Dismiss keyboard and remove focus from any text field
    FocusScope.of(context).unfocus();
    
    final result = await DecisionPendingFromUtils.showDecisionPendingFromPicker(
      context: context,
      catSubId: _selectedCategory!.catSubId,
      initialAgency: _selectedAgency,
      initialOther: _otherPendingByController.text.trim().isNotEmpty 
          ? _otherPendingByController.text.trim() 
          : null,
    );
    
    if (result != null) {
      setState(() {
        _selectedAgency = result['agency'];
        _otherPendingByController.text = result['other'] ?? '';
      });
    }
    
    // Ensure keyboard stays dismissed after modal closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Task',
        showBackButton: true,
        showDrawer: false,
        onBackPressed: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard first
          Navigator.pop(context, false); // Return false when user presses back
        },
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            )
          : GestureDetector(
              onTap: () {
                // Dismiss keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Category Selection
                  _buildCategorySelection(),
                  SizedBox(height: 24),

                  // Form based on selected category
                  if (_selectedCategory != null) ...[
                    // Task Name field for all categories
                    _buildTaskNameField(),
                    SizedBox(height: 16),
                    
                    if (_isSimpleTask) ...[
                      _buildSimpleTaskForm(),
                    ] else if (_isNormalTask) ...[
                      _buildNormalTaskForm(),
                    ],
                    SizedBox(height: 32),

                    // Common sections
                    _buildImagesSection(),
                    SizedBox(height: 24),
                    _buildActionButtonsSection(),
                    SizedBox(height: 32),

                    // Create Button
                    _buildCreateButton(),
                    SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Category *',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus(); // Dismiss keyboard first
              _showCategorySelectionModal();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory?.name ?? 'Choose a category',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _selectedCategory != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleTaskForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agency Selection
        Text(
          'Agency *',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8),
        
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Dismiss keyboard first
            _showAgencySelectionModal();
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getAgencyDisplayText(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: _selectedAgency != null && _selectedAgency!.isNotEmpty ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Date Fields in one row
        Row(
          children: [
            // Asking Date
            Expanded(
              child: CustomDatePickerField(
                controller: _askingDateController,
                label: 'Asking Date',
                hintText: 'Select asking date (optional)',
              ),
            ),
            SizedBox(width: 16),
            // Requirement Date
            Expanded(
              child: CustomDatePickerField(
                controller: _requirementDateController,
                label: 'Requirement Date',
                hintText: 'Select requirement date (optional)',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskNameField() {
    return CustomTextField(
      controller: _taskNameController,
      label: 'Task Name *',
      hintText: 'Enter task name',
    );
  }

  Widget _buildNormalTaskForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Date Fields in one row
        Row(
          children: [
            // Start Date
            Expanded(
              child: CustomDatePickerField(
                controller: _startDateController,
                label: 'Start Date',
                hintText: 'Select start date (optional)',
              ),
            ),
            SizedBox(width: 16),
            // End Date
            Expanded(
              child: CustomDatePickerField(
                controller: _endDateController,
                label: 'End Date',
                hintText: 'Select end date (optional)',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // QC Category
        Text(
          'QC Category',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8),

          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus(); // Dismiss keyboard first
              _showQcCategorySelectionModal();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedQcCategory?.name ?? 'Select QC category (optional)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _selectedQcCategory != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16),

        // Add Photos Button
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Dismiss keyboard first
            _pickImages();
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(Icons.add_photo_alternate, color: Theme.of(context).colorScheme.primary, size: 32),
          ),
        ),
        
        // Show selected images count and previews
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            '${_selectedImages.length} photo(s) selected',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          // Image previews
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
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
                            _selectedImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.borderColor,
                                child: Icon(
                                  Icons.error,
                                  color: Theme.of(context).colorScheme.error,
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
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
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
      ],
    );
  }

  Widget _buildActionButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16),
        
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.mic,
                label: 'Voice Notes',
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard first
                  _showVoiceNotesModal();
                },
                hasData: false, // TODO: Add voice notes functionality
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.people,
                label: 'Assign',
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard first
                  _showUserAssignmentModal();
                },
                hasData: _selectedUsers.isNotEmpty,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.note,
                label: 'Remark',
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard first
                  _showAddDataModal('remark', 'Remark');
                },
                hasData: _remarkController.text.isNotEmpty,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.assignment,
                label: 'Instructions',
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard first
                  _showAddDataModal('instructions', 'Instructions');
                },
                hasData: _instructionsController.text.isNotEmpty,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.comment,
                label: 'Comments',
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard first
                  _showAddDataModal('comments', 'Comments');
                },
                hasData: _commentsController.text.isNotEmpty,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(), // Empty space for balance
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool hasData,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: hasData ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasData ? Theme.of(context).colorScheme.primary : AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: hasData ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: hasData ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: hasData ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDataModal(String type, String title) {
    // Dismiss keyboard and remove focus from any text field
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildAddDataModal(type, title),
      ),
    ).then((_) {
      // Ensure keyboard stays dismissed after modal closes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).unfocus();
      });
    });
  }

  Widget _buildAddDataModal(String type, String title) {
    // Create a focus node for the text field
    final FocusNode textFieldFocusNode = FocusNode();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add $title',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () {
                    textFieldFocusNode.dispose();
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context, false); // Return false to indicate cancellation
                  },
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Input field
          Padding(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              children: [
                TextField(
                  controller: _getControllerForType(type),
                  focusNode: textFieldFocusNode,
                  maxLines: 3,
                  autofocus: true, // Automatically focus the text field
                  decoration: InputDecoration(
                    hintText: 'Enter $title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      textFieldFocusNode.dispose();
                      Navigator.pop(context, false); // Return false to indicate cancellation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController _getControllerForType(String type) {
    switch (type) {
      case 'remark':
        return _remarkController;
      case 'comments':
        return _commentsController;
      case 'instructions':
        return _instructionsController;
      default:
        return _remarkController;
    }
  }

  void _showVoiceNotesModal() {
    // TODO: Implement voice notes functionality
    SnackBarUtils.showInfo(
      context,
      message: 'Voice notes functionality coming soon!',
    );
  }


  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: _isLoading ? null : _createTask,
        text: _isLoading ? 'Creating...' : 'Create Task',
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _pickImages() async {
    // Dismiss keyboard and remove focus from any text field
    FocusScope.of(context).unfocus();
    
    final List<File> images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: true,
      maxImages: 10,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
    
    // Ensure keyboard stays dismissed after image picker closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  void _resetForm() {
    _categoryNameTitleController.clear();
    _categoryNameRequiredByController.clear();
    _otherPendingByController.clear();
    _askingDateController.clear();
    _requirementDateController.clear();
    _remarkController.clear();
    _commentsController.clear();
    _instructionsController.clear();
    _taskNameController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _selectedQcCategory = null;
    _selectedAgency = null;
    _selectedUsers.clear();
    _selectedImages.clear();
  }

  Future<void> _createTask() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    // Validate required fields based on task type
    if (_selectedCategory == null) {
      SnackBarUtils.showError(context, message: 'Please select a category');
      return;
    }

    // Required validations for all categories
    if (_taskNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter task name');
      return;
    }

    if (_isSimpleTask) {
      // Required validations for simple tasks (cat_sub_id 2,3,4,6)
      if (_selectedAgency == null || _selectedAgency!.trim().isEmpty) {
        SnackBarUtils.showError(context, message: 'Please select an agency');
        return;
      }
      
      // Check if any agencies are selected
      final agencies = _selectedAgency!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (agencies.isEmpty) {
        SnackBarUtils.showError(context, message: 'Please select an agency');
        return;
      }
      
      // Special validation for cat_sub_id 6 (Selection)
      if (_selectedCategory!.catSubId == 6 && agencies.isEmpty) {
        SnackBarUtils.showError(context, message: 'Please select at least one option for Selection Required By...!');
        return;
      }
      
      // Validation for "Other" agency
      if (agencies.contains("Other") && _otherPendingByController.text.trim().isEmpty) {
        SnackBarUtils.showError(context, message: 'Please specify other pending by');
        return;
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

      // Prepare request data based on task type
      final Map<String, String> requestFields = {
        'api_token': apiToken,
        'site_id': widget.site.id.toString(),
        'category_id': _selectedCategory!.id.toString(),
        'notes': _remarkController.text.trim(),
        'instruction': _instructionsController.text.trim(),
        'comment': _commentsController.text.trim(),
        'assign_to': _selectedUsers.map((user) => user.id.toString()).join(','),
        'unit': '%',
        'tag': '',
        'progress': '',
      };

      // Add task name for all categories
      requestFields['name'] = _taskNameController.text.trim();

      // Add task type specific fields
      if (_isSimpleTask) {
        // Simple task fields (cat_sub_id 2,3,4,6)
        requestFields['decision_by_agency'] = _selectedAgency!;
        requestFields['decision_pending_from'] = DateFormat('dd-MM-yyyy').format(DateTime.now());
        
        // Handle "Other" agency text
        final agencies = _selectedAgency!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        requestFields['decision_pending_other'] = agencies.contains("Other") ? _otherPendingByController.text.trim() : '';
        
        // Only add date fields if they have values
        if (_askingDateController.text.trim().isNotEmpty) {
          requestFields['start_date'] = _askingDateController.text.trim();
        }
        if (_requirementDateController.text.trim().isNotEmpty) {
          requestFields['end_date'] = _requirementDateController.text.trim();
        }
        
        requestFields['total_work'] = '100';
        requestFields['qc_category_id'] = '0';
      } else if (_isNormalTask) {
        // Normal task fields (cat_sub_id 5)
        
        // Only add date fields if they have values
        if (_startDateController.text.trim().isNotEmpty) {
          requestFields['start_date'] = _startDateController.text.trim();
        }
        if (_endDateController.text.trim().isNotEmpty) {
          requestFields['end_date'] = _endDateController.text.trim();
        }
        
        requestFields['qc_category_id'] = _selectedQcCategory?.id.toString() ?? '0';
        requestFields['total_work'] = '100';
        requestFields['decision_by_agency'] = '';
        requestFields['decision_pending_from'] = '';
        requestFields['decision_pending_other'] = '';
      }

      // Create multipart request
      final url = Uri.parse('${ApiService.baseUrl}/api/createTask');
      final request = http.MultipartRequest('POST', url);
      
      // Add fields
      requestFields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add images
      for (var imageFile in _selectedImages) {
        String fileName = path.basename(imageFile.path);
        String extension = path.extension(fileName).toLowerCase();
        String mimeType;

        switch (extension) {
          case '.jpg':
          case '.jpeg':
            mimeType = 'image/jpeg';
            break;
          case '.png':
            mimeType = 'image/png';
            break;
          default:
            mimeType = 'application/octet-stream';
        }

        var file = await http.MultipartFile.fromPath(
          "images[]",
          imageFile.path,
          contentType: MediaType.parse(mimeType),
          filename: fileName,
        );
        request.files.add(file);
      }

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);


      log("Create Task Response == $responseData");


      if (response.statusCode == 200 && jsonResponse['status'] == 1) {
        SnackBarUtils.showSuccess(context, message: 'Task created successfully');
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        SnackBarUtils.showError(
          context, 
          message: jsonResponse['message'] ?? 'Failed to create task'
        );
        Navigator.pop(context, false); // Return false to indicate failure
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to create task: $e');
      Navigator.pop(context, false); // Return false to indicate failure
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Modal Methods
  Future<void> _showCategorySelectionModal() async {
    // Dismiss keyboard and remove focus from any text field
    FocusScope.of(context).unfocus();
    
    final selectedCategory = await CategoryPickerUtils.showCategoryPicker(
      context: context,
      siteId: widget.site.id,
      allowedSubIds: [2,3,4,5,6]
    );
    
    if (selectedCategory != null) {
      setState(() {
        _selectedCategory = selectedCategory;
        _resetForm();
      });
    }
    
    // Ensure keyboard stays dismissed after modal closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }



  Future<void> _showQcCategorySelectionModal() async {
    // Dismiss keyboard and remove focus from any text field
    FocusScope.of(context).unfocus();
    
    final selectedQcCategory = await QcCategoryPickerUtils.showQcCategoryPicker(
      context: context,
      selectedCategory: _selectedQcCategory,
    );
    
    if (selectedQcCategory != null) {
      setState(() {
        _selectedQcCategory = selectedQcCategory;
      });
    }
    
    // Ensure keyboard stays dismissed after modal closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _showUserAssignmentModal() async {
    // Dismiss keyboard and remove focus from any text field
    FocusScope.of(context).unfocus();
    
    final selectedUsers = await UserAssignmentUtils.showSimpleUserAssignmentModal(
      context: context,
      siteId: widget.site.id,
      preSelectedUsers: _selectedUsers,
    );
    
    if (selectedUsers != null) {
      setState(() {
        _selectedUsers = selectedUsers;
      });
    }
    
    // Ensure keyboard stays dismissed after modal closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }








}
