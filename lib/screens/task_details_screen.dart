import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/task_detail_model.dart';
import '../models/task_model.dart';
import '../models/unit_model.dart';
import '../models/site_user_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/utils/unit_picker_utils.dart';
import '../core/utils/date_picker_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../models/tag_model.dart';
import '../core/utils/validation_utils.dart';
import '../core/utils/decision_pending_from_utils.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/attachment_viewer.dart';
import '../widgets/file_viewer.dart';
import '../models/unified_image_model.dart';
import '../models/unified_attachment_model.dart';
import '../models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'update_task_screen.dart';

// State holder class for question expansion
class _QuestionStateHolder {
  bool isRemarksExpanded = false;
}

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;
  final Function(TaskModel)? onTaskUpdated;

  const TaskDetailsScreen({super.key, required this.task, this.onTaskUpdated});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen>
    with TickerProviderStateMixin {
  TaskDetailModel? _taskDetail;
  bool _isLoading = true;
  bool _isSubmitting = false;
  TabController? _tabController;
  
  // Map to store state holders for each question
  final Map<int, _QuestionStateHolder> _questionStateHolders = {};

  // Unit-related variables
  List<UnitModel> _units = [];
  UnitModel? _selectedUnit;
  bool _isLoadingUnits = false;
  final TextEditingController _totalWorkController = TextEditingController();

  // Date editing variables
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isUpdatingDates = false;

  // Tag-related variables
  List<TagModel> _availableTags = [];
  List<int> _selectedTagIds = [];
  bool _isLoadingTags = false;
  bool _isUpdatingTags = false;

  // User assignment variables
  List<SiteUserModel> _availableUsers = [];
  List<SiteUserModel> _siteUsers = [];
  List<int> _assignedUserIds = [];
  bool _isLoadingUsers = false;
  bool _isUpdatingAssignment = false;

  // Survey form controllers for cat_sub_id = 1
  final List<TextEditingController> _answerControllers = List.generate(
    5,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _remarkControllers = List.generate(
    5,
    (index) => TextEditingController(),
  );

  // Add data controllers
  final TextEditingController _addDataController = TextEditingController();
  bool _isAddingData = false;

  // Upload controllers
  bool _isUploadingImages = false;
  bool _isUploadingAttachments = false;

  // Decision pending from variables
  String? _selectedDecisionAgency;
  String? _otherDecisionText;

  // Site Survey variables
  List<Question> _surveyQuestions = [];
  Map<String, dynamic> _previousAnswers = {};
  String? _surveyErrorMessage;
  bool _isSubmittingSurvey = false;

  // Get or create state holder for a question
  _QuestionStateHolder _getQuestionStateHolder(int questionId) {
    if (!_questionStateHolders.containsKey(questionId)) {
      _questionStateHolders[questionId] = _QuestionStateHolder();
    }
    return _questionStateHolders[questionId]!;
  }

  // Default survey questions for Site Survey

  @override
  void initState() {
    log("Task - ${widget.task.id}");
    super.initState();
    _loadTaskDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController ??= TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    // Dispose controllers
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    for (var controller in _remarkControllers) {
      controller.dispose();
    }
    _totalWorkController.dispose();
    _addDataController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadTaskDetails() async {
    // Store current tab index before reloading
    final currentTabIndex = _tabController?.index ?? 0;

    setState(() {
      _isLoading = true;
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
        _isLoading = false;
      });

      // Update tab controller with correct length after task details are loaded
      if (_tabController != null) {
        _tabController!.dispose();
      }
      _tabController = TabController(length: _getTabCount(), vsync: this);

      // Restore the previous tab index
      if (currentTabIndex < _getTabCount()) {
        _tabController!.animateTo(currentTabIndex);
      }

      // If it's a Site Survey, initialize survey questions
      if (taskDetail.isSiteSurvey) {
        _initializeSurveyQuestions();
      }

      // Load units
      _loadUnits();

      // Load tags
      _loadTags();

      // Load users
      _loadUsers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to load task details: $e',
      );
    }
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoadingTags = true;
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

      final tagResponse = await ApiService.getTags(apiToken: apiToken);
      if (tagResponse.isSuccess) {
        setState(() {
          _availableTags = tagResponse.data;
          _isLoadingTags = false;
        });

        // Initialize selected tags from task detail
        if (_taskDetail != null) {
          _selectedTagIds = _taskDetail!.tagsData.map((tag) => tag.id).toList();
        }
      } else {
        setState(() {
          _isLoadingTags = false;
        });
        SnackBarUtils.showError(context, message: 'Failed to load tags');
      }
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
      SnackBarUtils.showError(context, message: 'Failed to load tags: $e');
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
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

      // Load all users and site users in parallel
      final allUserResponse = await ApiService.getAllUsers(apiToken: apiToken);
      final siteUserResponse = await ApiService.getUsersBySite(
        apiToken: apiToken,
        siteId: _taskDetail?.siteId ?? 0,
      );

      if (allUserResponse.isSuccess && siteUserResponse.isSuccess) {
        setState(() {
          _availableUsers = allUserResponse.users;
          _siteUsers = siteUserResponse.users;
          _isLoadingUsers = false;
        });

        // Initialize assigned users from task detail
        if (_taskDetail != null &&
            _taskDetail!.assignTo != null &&
            _taskDetail!.assignTo!.isNotEmpty) {
          _assignedUserIds = _taskDetail!.assignTo!
              .split(',')
              .map((id) => int.tryParse(id.trim()) ?? 0)
              .where((id) => id > 0)
              .toList();
        }
      } else {
        setState(() {
          _isLoadingUsers = false;
        });
        SnackBarUtils.showError(context, message: 'Failed to load users');
      }
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      SnackBarUtils.showError(context, message: 'Failed to load users: $e');
    }
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoadingUnits = true;
    });

    try {
      final unitResponse = await ApiService.getUnits();
      if (unitResponse != null && unitResponse.status == 1) {
        setState(() {
          _units = unitResponse.data;
          _isLoadingUnits = false;
        });

        // Set current unit if task has one
        if (_taskDetail?.unit != null) {
          _selectedUnit = _units.firstWhere(
            (unit) => unit.symbol == _taskDetail!.unit,
            orElse: () => _units.first,
          );
        }
      } else {
        setState(() {
          _isLoadingUnits = false;
        });
        SnackBarUtils.showError(context, message: 'Failed to load units');
      }
    } catch (e) {
      setState(() {
        _isLoadingUnits = false;
      });
      SnackBarUtils.showError(context, message: 'Failed to load units: $e');
    }
  }

  Future<void> _showUnitPicker() async {
    if (_units.isEmpty) {
      SnackBarUtils.showError(context, message: 'No units available');
      return;
    }

    // Check if task has progress
    final hasProgress = _taskDetail?.progressDetails.isNotEmpty == true;
    if (hasProgress) {
      SnackBarUtils.showError(
        context,
        message: 'Unit cannot be changed once progress is recorded',
      );
      return;
    }

    final selectedUnit = await UnitPickerUtils.showUnitPicker(
      context,
      units: _units,
      selectedUnit: _selectedUnit,
    );

    if (selectedUnit != null) {
      // If selected unit is not %, ask for total work
      if (selectedUnit.symbol != '%') {
        _showTotalWorkDialog(selectedUnit);
      } else {
        // Update task with % unit
        _updateTaskUnit(selectedUnit.symbol);
      }
    }
  }

  void _showTotalWorkDialog(UnitModel selectedUnit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Total Work'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please enter the total work amount for this task:'),
              SizedBox(height: 16),
              TextField(
                controller: _totalWorkController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Work',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _totalWorkController.clear();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_totalWorkController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _updateTaskUnit(selectedUnit.symbol);
                } else {
                  SnackBarUtils.showError(
                    context,
                    message: 'Please enter total work',
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTaskUnit(String unit) async {
    setState(() {
      _isSubmitting = true;
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

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': widget.task.id.toString(),
        'unit': unit,
      };

      // Add total_work if not % unit
      if (unit != '%' && _totalWorkController.text.trim().isNotEmpty) {
        requestData['total_work'] = _totalWorkController.text.trim();
      } else {
        requestData['total_work'] = "100";
      }

      final response = await ApiService.editTask(requestData);

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Unit updated successfully',
        );

        // Update the selected unit only after successful API response
        final updatedUnit = _units.firstWhere(
          (unitModel) => unitModel.symbol == unit,
          orElse: () => _units.first,
        );
        setState(() {
          _selectedUnit = updatedUnit;
        });

        // Reload task details to get updated data
        _loadTaskDetails();
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to update task',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to update task: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
      _totalWorkController.clear();
    }
  }

  Future<void> _showStartDatePicker() async {
    DateTime? initialDate = _selectedStartDate;

    if (initialDate == null && _taskDetail?.startDate != null) {
      try {
        // Try to parse the date from API format (yyyy-MM-dd)
        initialDate = DateTime.parse(_taskDetail!.startDate!);
      } catch (e) {
        // If parsing fails, use current date
        initialDate = DateTime.now();
      }
    }

    initialDate ??= DateTime.now();

    final selectedDateString = await DatePickerUtils.pickDate(
      context: context,
      initialDate: initialDate,
    );

    if (selectedDateString != null) {
      final selectedDate = DatePickerUtils.parseDate(selectedDateString);
      if (selectedDate != null) {
        setState(() {
          _selectedStartDate = selectedDate;
        });
        _updateTaskDates();
      }
    }
  }

  Future<void> _showEndDatePicker() async {
    DateTime? initialDate = _selectedEndDate;

    if (initialDate == null && _taskDetail?.endDate != null) {
      try {
        // Try to parse the date from API format (yyyy-MM-dd)
        initialDate = DateTime.parse(_taskDetail!.endDate!);
      } catch (e) {
        // If parsing fails, use current date
        initialDate = DateTime.now();
      }
    }

    initialDate ??= DateTime.now();

    final selectedDateString = await DatePickerUtils.pickDate(
      context: context,
      initialDate: initialDate,
    );

    if (selectedDateString != null) {
      final selectedDate = DatePickerUtils.parseDate(selectedDateString);
      if (selectedDate != null) {
        setState(() {
          _selectedEndDate = selectedDate;
        });
        _updateTaskDates();
      }
    }
  }

  Future<void> _showTagSelectionModal() async {
    // Create a temporary list for the modal
    List<int> tempSelectedTagIds = List.from(_selectedTagIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTagSelectionModal(tempSelectedTagIds),
    );
  }

  Future<void> _showUserAssignmentModal() async {
    // Create a temporary list for the modal
    List<int> tempAssignedUserIds = List.from(_assignedUserIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserAssignmentModal(tempAssignedUserIds),
    );
  }

  Future<void> _showDecisionSelectionModal() async {
    // Check if user has permission to change decision
    if (!ValidationUtils.canChangeDecisionPendingFrom(_taskDetail!)) {
      SnackBarUtils.showError(
        context,
        message: 'You do not have permission to change this decision',
      );
      return;
    }

    final result = await DecisionPendingFromUtils.showDecisionPendingFromPicker(
      context: context,
      catSubId: _taskDetail!.catSubId,
      initialAgency: _taskDetail?.decisionByAgency,
      initialOther: _taskDetail?.decisionPendingOther,
    );

    if (result != null) {
      // Update the local state
      _selectedDecisionAgency = result['agency'];
      _otherDecisionText = result['other'];
      
      // Call the update method
      await _updateTaskDecisionFromModal();
    }
  }

  void _showAddDataModal(String type, String title) {
    _addDataController.clear();
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
    );
  }

  Widget _buildAddDataModal(String type, String title) {
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
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form
          Padding(
            padding: ResponsiveUtils.horizontalPadding(context),
            child: Column(
              children: [
                TextField(
                  controller: _addDataController,
                  maxLines: type == 'price' ? 1 : 5,
                  keyboardType: type == 'price'
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    hintText: type == 'price'
                        ? 'Enter price amount...'
                        : 'Enter your $title...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  autofocus: true,
                ),

                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAddingData ? null : () => _addData(type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
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
                    child: _isAddingData
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Save',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom padding
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addData(String type) async {
    if (_addDataController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter some text');
      return;
    }

    setState(() {
      _isAddingData = true;
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

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': widget.task.id.toString(),
      };

      // Add the appropriate field based on type
      switch (type) {
        case 'notes':
          requestData['notes'] = _addDataController.text.trim();
          break;
        case 'instruction':
          requestData['instruction'] = _addDataController.text.trim();
          break;
        case 'comment':
          requestData['comment'] = _addDataController.text.trim();
          break;
        case 'remark':
          requestData['notes'] = _addDataController.text
              .trim(); // remarks use notes field
          break;
        case 'price':
          requestData['total_price'] = _addDataController.text.trim();
          break;
      }

      final response = await ApiService.editTask(requestData);

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message:
              '${type[0].toUpperCase() + type.substring(1)} added successfully',
        );

        // Update the task detail object with new data without reloading
        _updateTaskDetailLocally(type, _addDataController.text.trim());

        Navigator.pop(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to add ${type}',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to add ${type}: $e');
    } finally {
      setState(() {
        _isAddingData = false;
      });
    }
  }

  void _updateTaskDetailLocally(String type, String content) {
    if (_taskDetail == null) return;

    setState(() {
      // Get current user info
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return;

      // Create user model for the new entry
      final userModel = UserModel(
        id: currentUser.id,
        firstName: currentUser.firstName,
        lastName: currentUser.lastName,
        deviceId: currentUser.deviceId,
        mobile: currentUser.mobile,
        email: currentUser.email,
        userType: currentUser.userType,
        status: currentUser.status,
        siteId: currentUser.siteId,
        image: currentUser.image,
        lastActiveTime: currentUser.lastActiveTime,
        createdAt: currentUser.createdAt,
        updatedAt: currentUser.updatedAt,
        deletedAt: currentUser.deletedAt,
        imageUrl: currentUser.imageUrl,
        apiToken: currentUser.apiToken,
      );

      // Create new entry based on type
      switch (type) {
        case 'instruction':
          final newInstruction = TaskInstructionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            // Temporary ID
            instruction: content,
            userId: currentUser.id,
            taskId: _taskDetail!.id,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            user: userModel,
          );
          _taskDetail = _taskDetail!.copyWith(
            instructions: [..._taskDetail!.instructions, newInstruction],
          );
          break;

        case 'remark':
          final newRemark = TaskRemarkModel(
            id: DateTime.now().millisecondsSinceEpoch,
            // Temporary ID
            remark: content,
            userId: currentUser.id,
            taskId: _taskDetail!.id,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            user: userModel,
          );
          _taskDetail = _taskDetail!.copyWith(
            remarks: [..._taskDetail!.remarks, newRemark],
          );
          break;

        case 'comment':
          final newComment = TaskCommentModel(
            id: DateTime.now().millisecondsSinceEpoch,
            // Temporary ID
            comment: content,
            userId: currentUser.id,
            taskId: _taskDetail!.id,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            user: userModel,
          );
          _taskDetail = _taskDetail!.copyWith(
            comments: [..._taskDetail!.comments, newComment],
          );
          break;

        case 'price':
          _taskDetail = _taskDetail!.copyWith(totalPrice: content);
          break;
      }
    });
  }

  void _updateTaskImagesLocally(List<File> images) {
    if (_taskDetail == null) return;

    setState(() {
      // Get current user info
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return;

      // Create new image models from uploaded files
      final newImages = images
          .map(
            (file) => TaskImageModel(
              id: DateTime.now().millisecondsSinceEpoch + images.indexOf(file),
              // Temporary ID
              imagePath: file.path,
              // Store local file path
              taskId: _taskDetail!.id,
              image: file.path.split('/').last,
              // Use filename as image
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            ),
          )
          .toList();

      // Add new images to the beginning of existing images
      _taskDetail = _taskDetail!.copyWith(
        images: [...newImages, ..._taskDetail!.images],
      );
    });
  }

  void _updateTaskAttachmentsLocally(List<File> attachments) {
    if (_taskDetail == null) return;

    setState(() {
      // Get current user info
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return;

      // Create new attachment models from uploaded files
      final newAttachments = attachments
          .map((file) => file.path.split('/').last)
          .toList();

      // Add new attachments to the beginning of existing attachments
      _taskDetail = _taskDetail!.copyWith(
        attachments: [...newAttachments, ..._taskDetail!.attachments],
      );
    });
  }

  Future<void> _pickAndUploadImages() async {
    final List<File> images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: true,
      maxImages: 10,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      await _uploadImages(images);
    }
  }

  Future<void> _pickAndUploadAttachments() async {
    final List<File> attachments =
        await ImagePickerUtils.pickDocumentsWithSource(
          context: context,
          maxFiles: 10,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'txt',
            'rtf',
          ],
        );

    if (attachments.isNotEmpty) {
      await _uploadAttachments(attachments);
    }
  }

  Future<void> _uploadImages(List<File> images) async {
    setState(() {
      _isUploadingImages = true;
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

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/editTask'),
      );

      // Add text fields
      request.fields['api_token'] = apiToken;
      request.fields['task_id'] = widget.task.id.toString();

      // Add image files
      for (File image in images) {
        final stream = http.ByteStream(image.openRead());
        final length = await image.length();
        final multipartFile = http.MultipartFile(
          'images[]',
          stream,
          length,
          filename: image.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 1) {
          SnackBarUtils.showSuccess(
            context,
            message: 'Images uploaded successfully',
          );

          // Reload task details to get proper image URLs from server
          _loadTaskDetails();
        } else {
          SnackBarUtils.showError(
            context,
            message: responseData['message'] ?? 'Failed to upload images',
          );
        }
      } else {
        SnackBarUtils.showError(context, message: 'Failed to upload images');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to upload images: $e');
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  Future<void> _uploadAttachments(List<File> attachments) async {
    setState(() {
      _isUploadingAttachments = true;
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

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/editTask'),
      );

      // Add text fields
      request.fields['api_token'] = apiToken;
      request.fields['task_id'] = widget.task.id.toString();

      // Add attachment files
      for (File attachment in attachments) {
        final stream = http.ByteStream(attachment.openRead());
        final length = await attachment.length();
        final multipartFile = http.MultipartFile(
          'attachments[]',
          stream,
          length,
          filename: attachment.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 1) {
          SnackBarUtils.showSuccess(
            context,
            message: 'Attachments uploaded successfully',
          );

          // Update task details locally without reloading
          _updateTaskAttachmentsLocally(attachments);
        } else {
          SnackBarUtils.showError(
            context,
            message: responseData['message'] ?? 'Failed to upload attachments',
          );
        }
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Failed to upload attachments',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to upload attachments: $e',
      );
    } finally {
      setState(() {
        _isUploadingAttachments = false;
      });
    }
  }

  Widget _buildTagSelectionModal(List<int> tempSelectedTagIds) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Select Tags',
                            style: AppTypography.titleLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Tags list
                    Expanded(
                      child: _isLoadingTags
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _availableTags.length,
                              itemBuilder: (context, index) {
                                final tag = _availableTags[index];
                                final isSelected = tempSelectedTagIds.contains(
                                  tag.id,
                                );

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      if (isSelected) {
                                        tempSelectedTagIds.remove(tag.id);
                                      } else {
                                        tempSelectedTagIds.add(tag.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary.withOpacity(
                                              0.1,
                                            )
                                          : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : AppColors.borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tag.name,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Action buttons
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingTags
                                  ? null
                                  : () => _updateTaskTagsFromModal(
                                      tempSelectedTagIds,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isUpdatingTags
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Update Tags',
                                      style: AppTypography.bodyMedium.copyWith(
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
                ),
              );
            },
          ),
        );
      },
    );
  }



  Widget _buildUserAssignmentModal(List<int> tempAssignedUserIds) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Assign Users to Task',
                            style: AppTypography.titleLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Users list
                    Expanded(
                      child: _isLoadingUsers
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _siteUsers.length,
                              itemBuilder: (context, index) {
                                final user = _siteUsers[index];
                                final isAssigned = tempAssignedUserIds.contains(
                                  user.id,
                                );

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      if (isAssigned) {
                                        tempAssignedUserIds.remove(user.id);
                                      } else {
                                        tempAssignedUserIds.add(user.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isAssigned
                                          ? Theme.of(context).colorScheme.primary.withOpacity(
                                              0.1,
                                            )
                                          : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isAssigned
                                            ? Theme.of(context).colorScheme.primary
                                            : AppColors.borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // User avatar
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),

                                        // User info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.fullName,
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                      color:
                                                          Theme.of(context).colorScheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                user.email,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Assign/Remove button
                                        GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              if (isAssigned) {
                                                tempAssignedUserIds.remove(
                                                  user.id,
                                                );
                                              } else {
                                                tempAssignedUserIds.add(
                                                  user.id,
                                                );
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isAssigned
                                                  ? Theme.of(context).colorScheme.error
                                                  : Theme.of(context).colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isAssigned ? 'Remove' : 'Assign',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
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

                    // Action buttons
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdatingAssignment
                                  ? null
                                  : () => _updateTaskAssignmentFromModal(
                                      tempAssignedUserIds,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isUpdatingAssignment
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Update Assignment',
                                      style: AppTypography.bodyMedium.copyWith(
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _updateTaskTagsFromModal(List<int> tempSelectedTagIds) async {
    setState(() {
      _isUpdatingTags = true;
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

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': widget.task.id.toString(),
        'tag': tempSelectedTagIds.join(','),
      };

      final response = await ApiService.editTask(requestData);

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Tags updated successfully',
        );

        // Update the main state with the temporary selection
        setState(() {
          _selectedTagIds = List.from(tempSelectedTagIds);
        });

        // Update the task detail object with new tags
        if (_taskDetail != null) {
          setState(() {
            // Create new tag models from selected IDs
            final updatedTags = tempSelectedTagIds.map((tagId) {
              final tag = _availableTags.firstWhere(
                (t) => t.id == tagId,
                orElse: () => TagModel(
                  id: tagId,
                  name: 'Tag $tagId',
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                ),
              );
              return tag;
            }).toList();

            // Create a new task detail object with updated tags
            final updatedTaskDetail = TaskDetailModel(
              id: _taskDetail!.id,
              name: _taskDetail!.name,
              notes: _taskDetail!.notes,
              comment: _taskDetail!.comment,
              siteId: _taskDetail!.siteId,
              createdBy: _taskDetail!.createdBy,
              assignTo: _taskDetail!.assignTo,
              startDate: _taskDetail!.startDate,
              endDate: _taskDetail!.endDate,
              progress: _taskDetail!.progress,
              totalWorkDone: _taskDetail!.totalWorkDone,
              totalWork: _taskDetail!.totalWork,
              categoryId: _taskDetail!.categoryId,
              voiceNote: _taskDetail!.voiceNote,
              totalPrice: _taskDetail!.totalPrice,
              tag: tempSelectedTagIds.join(','),
              status: _taskDetail!.status,
              unit: _taskDetail!.unit,
              decisionByAgency: _taskDetail!.decisionByAgency,
              decisionPendingOther: _taskDetail!.decisionPendingOther,
              completionDate: _taskDetail!.completionDate,
              decisionPendingFrom: _taskDetail!.decisionPendingFrom,
              qcCategoryId: _taskDetail!.qcCategoryId,
              createdAt: _taskDetail!.createdAt,
              updatedAt: _taskDetail!.updatedAt,
              deletedAt: _taskDetail!.deletedAt,
              tagsData: updatedTags,
              categoryName: _taskDetail!.categoryName,
              catSubId: _taskDetail!.catSubId,
              assignedUserName: _taskDetail!.assignedUserName,
              qcPdf: _taskDetail!.qcPdf,
              voiceNotePath: _taskDetail!.voiceNotePath,
              createdUser: _taskDetail!.createdUser,
              images: _taskDetail!.images,
              instructions: _taskDetail!.instructions,
              progressDetails: _taskDetail!.progressDetails,
              remarks: _taskDetail!.remarks,
              comments: _taskDetail!.comments,
              qualityChecks: _taskDetail!.qualityChecks,
              attachments: _taskDetail!.attachments,
              voiceNotes: _taskDetail!.voiceNotes,
            );
            _taskDetail = updatedTaskDetail;
          });
        }

        Navigator.pop(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to update tags',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to update tags: $e');
    } finally {
      setState(() {
        _isUpdatingTags = false;
      });
    }
  }

  Future<void> _updateTaskDecisionFromModal() async {
    if (_selectedDecisionAgency == null) {
      SnackBarUtils.showError(context, message: 'Please select an agency');
      return;
    }

    if (_selectedDecisionAgency == 'Other') {
      if (_otherDecisionText == null || _otherDecisionText!.trim().isEmpty) {
        SnackBarUtils.showError(
          context,
          message: 'Please specify the other agency name',
        );
        return;
      }
      if (_otherDecisionText!.trim().length < 4) {
        SnackBarUtils.showError(
          context,
          message: 'Please enter at least 4 characters for the agency name',
        );
        return;
      }
    }

    setState(() {
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

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': widget.task.id.toString(),
        'decision_by_agency': _selectedDecisionAgency,
      };

      // Add decision_pending_other if "Other" is selected
      if (_selectedDecisionAgency == 'Other' && _otherDecisionText != null) {
        requestData['decision_pending_other'] = _otherDecisionText!.trim();
      }

      final response = await ApiService.editTask(requestData);

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Decision updated successfully',
        );

        // Update the task detail object with new decision
        if (_taskDetail != null) {
          setState(() {
            // Create a new task detail object with updated decision
            final updatedTaskDetail = TaskDetailModel(
              id: _taskDetail!.id,
              name: _taskDetail!.name,
              notes: _taskDetail!.notes,
              comment: _taskDetail!.comment,
              siteId: _taskDetail!.siteId,
              createdBy: _taskDetail!.createdBy,
              assignTo: _taskDetail!.assignTo,
              startDate: _taskDetail!.startDate,
              endDate: _taskDetail!.endDate,
              progress: _taskDetail!.progress,
              totalWorkDone: _taskDetail!.totalWorkDone,
              totalWork: _taskDetail!.totalWork,
              categoryId: _taskDetail!.categoryId,
              voiceNote: _taskDetail!.voiceNote,
              totalPrice: _taskDetail!.totalPrice,
              tag: _taskDetail!.tag,
              status: _taskDetail!.status,
              unit: _taskDetail!.unit,
              decisionByAgency: _selectedDecisionAgency,
              decisionPendingOther: _selectedDecisionAgency == 'Other'
                  ? _otherDecisionText
                  : _taskDetail!.decisionPendingOther,
              completionDate: _taskDetail!.completionDate,
              decisionPendingFrom: _taskDetail!.decisionPendingFrom,
              qcCategoryId: _taskDetail!.qcCategoryId,
              createdAt: _taskDetail!.createdAt,
              updatedAt: _taskDetail!.updatedAt,
              deletedAt: _taskDetail!.deletedAt,
              tagsData: _taskDetail!.tagsData,
              categoryName: _taskDetail!.categoryName,
              catSubId: _taskDetail!.catSubId,
              assignedUserName: _taskDetail!.assignedUserName,
              qcPdf: _taskDetail!.qcPdf,
              voiceNotePath: _taskDetail!.voiceNotePath,
              createdUser: _taskDetail!.createdUser,
              images: _taskDetail!.images,
              instructions: _taskDetail!.instructions,
              progressDetails: _taskDetail!.progressDetails,
              remarks: _taskDetail!.remarks,
              comments: _taskDetail!.comments,
              qualityChecks: _taskDetail!.qualityChecks,
              attachments: _taskDetail!.attachments,
              voiceNotes: _taskDetail!.voiceNotes,
            );
            _taskDetail = updatedTaskDetail;
          });
        }

        Navigator.pop(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to update decision',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to update decision: $e',
      );
    } finally {
      setState(() {
      });
    }
  }

  Future<void> _updateTaskAssignmentFromModal(
    List<int> tempAssignedUserIds,
  ) async {
    setState(() {
      _isUpdatingAssignment = true;
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

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': widget.task.id.toString(),
        'assign_to': tempAssignedUserIds.join(','),
      };

      final response = await ApiService.editTask(requestData);

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Task assignment updated successfully',
        );

        // Update the main state with the temporary selection
        setState(() {
          _assignedUserIds = List.from(tempAssignedUserIds);
        });

        // Update the task detail object with new assignment
        if (_taskDetail != null) {
          setState(() {
            // Create a new task detail object with updated assignment
            final updatedTaskDetail = TaskDetailModel(
              id: _taskDetail!.id,
              name: _taskDetail!.name,
              notes: _taskDetail!.notes,
              comment: _taskDetail!.comment,
              siteId: _taskDetail!.siteId,
              createdBy: _taskDetail!.createdBy,
              assignTo: tempAssignedUserIds.join(','),
              startDate: _taskDetail!.startDate,
              endDate: _taskDetail!.endDate,
              progress: _taskDetail!.progress,
              totalWorkDone: _taskDetail!.totalWorkDone,
              totalWork: _taskDetail!.totalWork,
              categoryId: _taskDetail!.categoryId,
              voiceNote: _taskDetail!.voiceNote,
              totalPrice: _taskDetail!.totalPrice,
              tag: _taskDetail!.tag,
              status: _taskDetail!.status,
              unit: _taskDetail!.unit,
              decisionByAgency: _taskDetail!.decisionByAgency,
              decisionPendingOther: _taskDetail!.decisionPendingOther,
              completionDate: _taskDetail!.completionDate,
              decisionPendingFrom: _taskDetail!.decisionPendingFrom,
              qcCategoryId: _taskDetail!.qcCategoryId,
              createdAt: _taskDetail!.createdAt,
              updatedAt: _taskDetail!.updatedAt,
              deletedAt: _taskDetail!.deletedAt,
              tagsData: _taskDetail!.tagsData,
              categoryName: _taskDetail!.categoryName,
              catSubId: _taskDetail!.catSubId,
              assignedUserName: _taskDetail!.assignedUserName,
              qcPdf: _taskDetail!.qcPdf,
              voiceNotePath: _taskDetail!.voiceNotePath,
              createdUser: _taskDetail!.createdUser,
              images: _taskDetail!.images,
              instructions: _taskDetail!.instructions,
              progressDetails: _taskDetail!.progressDetails,
              remarks: _taskDetail!.remarks,
              comments: _taskDetail!.comments,
              qualityChecks: _taskDetail!.qualityChecks,
              attachments: _taskDetail!.attachments,
              voiceNotes: _taskDetail!.voiceNotes,
            );
            _taskDetail = updatedTaskDetail;
          });
        }

        // Update the parent screen with the updated task data
        if (widget.onTaskUpdated != null) {
          // Create user models for the assigned users
          final assignedUsers = _siteUsers
              .where((user) => tempAssignedUserIds.contains(user.id))
              .map(
                (siteUser) => UserModel(
                  id: siteUser.id,
                  firstName: siteUser.firstName,
                  lastName: siteUser.lastName,
                  deviceId: siteUser.deviceId,
                  mobile: siteUser.mobile,
                  email: siteUser.email,
                  userType: siteUser.userType,
                  status: siteUser.status,
                  siteId: siteUser.siteId,
                  image: siteUser.image,
                  lastActiveTime: siteUser.createdAt,
                  // Use createdAt as fallback
                  createdAt: siteUser.createdAt,
                  updatedAt: siteUser.updatedAt,
                  deletedAt: null,
                  // SiteUserModel doesn't have deletedAt
                  imageUrl: siteUser.imageUrl,
                  apiToken: '', // Empty string as fallback
                ),
              )
              .toList();

          final updatedTask = widget.task.copyWith(
            assignTo: tempAssignedUserIds.join(','),
            assign: assignedUsers,
          );
          widget.onTaskUpdated!(updatedTask);
        }

        Navigator.pop(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to update task assignment',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to update task assignment: $e',
      );
    } finally {
      setState(() {
        _isUpdatingAssignment = false;
      });
    }
  }

  Future<void> _updateTaskTags() async {
    setState(() {
      _isUpdatingTags = true;
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

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': widget.task.id.toString(),
        'tag': _selectedTagIds.join(','),
      };

      final response = await ApiService.editTask(requestData);

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Tags updated successfully',
        );

        // Update the task detail object with new tags
        if (_taskDetail != null) {
          setState(() {
            // Create new tag models from selected IDs
            final updatedTags = _selectedTagIds.map((tagId) {
              final tag = _availableTags.firstWhere(
                (t) => t.id == tagId,
                orElse: () => TagModel(
                  id: tagId,
                  name: 'Tag $tagId',
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                ),
              );
              return tag;
            }).toList();

            // Create a new task detail object with updated tags
            final updatedTaskDetail = TaskDetailModel(
              id: _taskDetail!.id,
              name: _taskDetail!.name,
              notes: _taskDetail!.notes,
              comment: _taskDetail!.comment,
              siteId: _taskDetail!.siteId,
              createdBy: _taskDetail!.createdBy,
              assignTo: _taskDetail!.assignTo,
              startDate: _taskDetail!.startDate,
              endDate: _taskDetail!.endDate,
              progress: _taskDetail!.progress,
              totalWorkDone: _taskDetail!.totalWorkDone,
              totalWork: _taskDetail!.totalWork,
              categoryId: _taskDetail!.categoryId,
              voiceNote: _taskDetail!.voiceNote,
              totalPrice: _taskDetail!.totalPrice,
              tag: _selectedTagIds.join(','),
              status: _taskDetail!.status,
              unit: _taskDetail!.unit,
              decisionByAgency: _taskDetail!.decisionByAgency,
              decisionPendingOther: _taskDetail!.decisionPendingOther,
              completionDate: _taskDetail!.completionDate,
              decisionPendingFrom: _taskDetail!.decisionPendingFrom,
              qcCategoryId: _taskDetail!.qcCategoryId,
              createdAt: _taskDetail!.createdAt,
              updatedAt: _taskDetail!.updatedAt,
              deletedAt: _taskDetail!.deletedAt,
              tagsData: updatedTags,
              categoryName: _taskDetail!.categoryName,
              catSubId: _taskDetail!.catSubId,
              assignedUserName: _taskDetail!.assignedUserName,
              qcPdf: _taskDetail!.qcPdf,
              voiceNotePath: _taskDetail!.voiceNotePath,
              createdUser: _taskDetail!.createdUser,
              images: _taskDetail!.images,
              instructions: _taskDetail!.instructions,
              progressDetails: _taskDetail!.progressDetails,
              remarks: _taskDetail!.remarks,
              comments: _taskDetail!.comments,
              qualityChecks: _taskDetail!.qualityChecks,
              attachments: _taskDetail!.attachments,
              voiceNotes: _taskDetail!.voiceNotes,
            );
            _taskDetail = updatedTaskDetail;
          });
        }

        Navigator.pop(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to update tags',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to update tags: $e');
    } finally {
      setState(() {
        _isUpdatingTags = false;
      });
    }
  }

  Future<void> _updateTaskDates() async {
    setState(() {
      _isUpdatingDates = true;
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

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': widget.task.id.toString(),
      };

      // Add start date if selected
      if (_selectedStartDate != null) {
        requestData['start_date'] = DatePickerUtils.getDateForAPI(
          _selectedStartDate!,
        );
      }

      // Add end date if selected
      if (_selectedEndDate != null) {
        requestData['end_date'] = DatePickerUtils.getDateForAPI(
          _selectedEndDate!,
        );
      }

      final response = await ApiService.editTask(requestData);

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Dates updated successfully',
        );

        // Update the task detail object with new dates
        if (_taskDetail != null) {
          setState(() {
            // Create a new task detail object with updated dates
            final updatedTaskDetail = TaskDetailModel(
              id: _taskDetail!.id,
              name: _taskDetail!.name,
              notes: _taskDetail!.notes,
              comment: _taskDetail!.comment,
              siteId: _taskDetail!.siteId,
              createdBy: _taskDetail!.createdBy,
              assignTo: _taskDetail!.assignTo,
              startDate: _selectedStartDate != null
                  ? DatePickerUtils.getDateForAPI(_selectedStartDate!)
                  : _taskDetail!.startDate,
              endDate: _selectedEndDate != null
                  ? DatePickerUtils.getDateForAPI(_selectedEndDate!)
                  : _taskDetail!.endDate,
              progress: _taskDetail!.progress,
              totalWorkDone: _taskDetail!.totalWorkDone,
              totalWork: _taskDetail!.totalWork,
              categoryId: _taskDetail!.categoryId,
              voiceNote: _taskDetail!.voiceNote,
              totalPrice: _taskDetail!.totalPrice,
              tag: _taskDetail!.tag,
              status: _taskDetail!.status,
              unit: _taskDetail!.unit,
              decisionByAgency: _taskDetail!.decisionByAgency,
              decisionPendingOther: _taskDetail!.decisionPendingOther,
              completionDate: _taskDetail!.completionDate,
              decisionPendingFrom: _taskDetail!.decisionPendingFrom,
              qcCategoryId: _taskDetail!.qcCategoryId,
              createdAt: _taskDetail!.createdAt,
              updatedAt: _taskDetail!.updatedAt,
              deletedAt: _taskDetail!.deletedAt,
              assignedUserName: _taskDetail!.assignedUserName,
              voiceNotePath: _taskDetail!.voiceNotePath,
              categoryName: _taskDetail!.categoryName,
              createdUser: _taskDetail!.createdUser,
              images: _taskDetail!.images,
              instructions: _taskDetail!.instructions,
              progressDetails: _taskDetail!.progressDetails,
              remarks: _taskDetail!.remarks,
              comments: _taskDetail!.comments,
              qualityChecks: _taskDetail!.qualityChecks,
              catSubId: _taskDetail!.catSubId,
              attachments: _taskDetail!.attachments,
              voiceNotes: _taskDetail!.voiceNotes,
              tagsData: _taskDetail!.tagsData,
            );
            _taskDetail = updatedTaskDetail;

            // Update the parent screen with the updated task data
            if (widget.onTaskUpdated != null) {
              final updatedTask = widget.task.copyWith(
                startDate: _selectedStartDate != null
                    ? DatePickerUtils.getDateForAPI(_selectedStartDate!)
                    : _taskDetail!.startDate,
                endDate: _selectedEndDate != null
                    ? DatePickerUtils.getDateForAPI(_selectedEndDate!)
                    : _taskDetail!.endDate,
              );
              widget.onTaskUpdated!(updatedTask);
            }

            // Clear selected dates
            _selectedStartDate = null;
            _selectedEndDate = null;
          });
        }
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to update dates',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to update dates: $e');
    } finally {
      setState(() {
        _isUpdatingDates = false;
      });
    }
  }

  void _populateSurveyForm(ProgressDetailModel progressDetail) {
    if (progressDetail.taskQuestions.isNotEmpty) {
      final questions = progressDetail.taskQuestions.first;
      final qaList = questions.questionsAndAnswers;

      for (int i = 0; i < qaList.length && i < 5; i++) {
        _answerControllers[i].text = qaList[i]['answer'] ?? '';
        _remarkControllers[i].text = qaList[i]['remark'] ?? '';
      }
    }
  }

  bool _validateSurveyForm() {
    for (int i = 0; i < 5; i++) {
      if (_answerControllers[i].text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _getAppBarTitle(),
          showBackButton: true,
          showDrawer: false,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              )
            : _buildTaskContent(),
        floatingActionButton: _taskDetail?.isSiteSurvey == true
            ? FloatingActionButton.extended(
                onPressed: _isSubmittingSurvey ? null : _submitSurvey,
                backgroundColor: _hasSurveyChanges()
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                foregroundColor: Colors.white,
                icon: _isSubmittingSurvey
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(
                  _isSubmittingSurvey ? 'Saving...' : 'Save Survey',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTaskContent() {
    if (_taskDetail == null) {
      return Center(
        child: Text(
          'Task details not found',
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // For all task types except Site Survey, use tabbed design
    final catSubId = _taskDetail!.catSubId;

    if (catSubId == 1) {
      return _buildSiteSurveyContent();
    } else {
      return _buildTabbedTaskContent();
    }
  }

  Widget _buildSiteSurveyContent() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSurveyForm(),

          if (_surveyErrorMessage != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.error),
              ),
              child: Text(
                _surveyErrorMessage!,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],

          SizedBox(height: 32),

          // Submit Button
          CustomButton(
            onPressed: _isSubmittingSurvey ? null : _submitSurvey,
            text: _isSubmittingSurvey ? 'Submitting...' : 'Submit Survey',
            isLoading: _isSubmittingSurvey,
            backgroundColor: _hasSurveyChanges()
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedTaskContent() {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.borderColor, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 2,
            isScrollable: true,
            // Make tabs swipeable
            tabAlignment: TabAlignment.start,
            // Align tabs to start
            tabs: _buildTabs(),
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _buildTabViews(),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskHeader() {
    final catSubId = _taskDetail?.catSubId;
    final isSiteSurvey = catSubId == 1;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _taskDetail?.name ?? 'Task',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getStatusColor(), width: 1),
                ),
                child: Text(
                  _taskDetail?.status ?? 'Pending',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12),
              if (_taskDetail?.progress != null)
                Text(
                  '${_taskDetail!.progress}% Complete',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 8),
              Text(
                isSiteSurvey
                    ? 'Survey Date: ${_taskDetail?.startDate ?? 'Not set'}'
                    : 'Start Date: ${_taskDetail?.startDate ?? 'Not set'}',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (!isSiteSurvey && _taskDetail?.endDate != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'End Date: ${_taskDetail?.endDate ?? 'Not set'}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===== TAB METHODS =====

  int _getTabCount() {
    final catSubId = _taskDetail?.catSubId;
    if (catSubId == 5) {
      return 9; // Details, Timeline, Instructions, Remarks, Comments, Photos, Attachments, Voice Notes, QC
    } else {
      return 7; // Details, Instructions, Remarks, Comments, Photos, Attachments, Voice Notes (no Timeline/QC for special tasks)
    }
  }

  List<Widget> _buildTabs() {
    final catSubId = _taskDetail?.catSubId;
    final tabs = <Widget>[
      Tab(
        child: Container(
          width: 80,
          child: Text(
            'Details',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    if (catSubId == 5) {
      tabs.add(
        Tab(
          child: Container(
            width: 80,
            child: Text(
              'Timeline',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    tabs.addAll([
      Tab(
        child: Container(
          width: 80,
          child: Text(
            'Instructions',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Tab(
        child: Container(
          width: 80,
          child: Text(
            'Remarks',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Tab(
        child: Container(
          width: 80,
          child: Text(
            'Comments',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Tab(
        child: Container(
          width: 80,
          child: Text(
            'Photos',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Tab(
        child: Container(
          width: 80,
          child: Text(
            'Attachments',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Tab(
        child: Container(
          width: 80,
          child: Text(
            'Voice Notes',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ]);

    if (catSubId == 5) {
      tabs.add(
        Tab(
          child: Container(
            width: 80,
            child: Text(
              'QC',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final catSubId = _taskDetail?.catSubId;
    final views = <Widget>[_buildDetailsTab()];

    if (catSubId == 5) {
      views.add(_buildTimelineTab());
    }

    views.addAll([
      _buildInstructionsTab(),
      _buildRemarksTab(),
      _buildCommentsTab(),
      _buildPhotosTab(),
      _buildAttachmentsTab(),
      _buildVoiceNotesTab(),
    ]);

    if (catSubId == 5) {
      views.add(_buildQCTab());
    }

    return views;
  }

  // ===== TAB CONTENT BUILDERS =====

  Widget _buildDetailsTab() {
    final catSubId = _taskDetail?.catSubId;
    final isSpecialTask = [2, 3, 4, 6].contains(catSubId);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit for Work Updates (only for Normal Tasks)
              if (catSubId == 5) ...[_buildUnitSection(), SizedBox(height: 12)],

              // Task Metadata
              _buildTaskMetadataCard(),
              SizedBox(height: 12),
              // Decision Section (only for Special Tasks)
              if (isSpecialTask) ...[
                _buildDecisionSection(),
                SizedBox(height: 12),
              ],

              // Timeline Section (only for Normal Tasks)
              if (catSubId == 5) ...[
                _buildTimelineSection(),
                SizedBox(height: 16),
              ],

              // Instructions Section
              _buildInstructionsSection(),
              SizedBox(height: 16),

              // Remarks Section
              _buildRemarksSection(),
              SizedBox(height: 16),

              // Comments Section
              _buildCommentsSection(),
              SizedBox(height: 16),

              // Photos Card
              _buildPhotosCard(),
              SizedBox(height: 12),

              // Attachments Card
              _buildAttachmentsCard(),

              SizedBox(height: 60),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: _taskDetail?.progress == 100
                ? SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.green,
                        elevation: 4,
                        shadowColor: Theme.of(context).colorScheme.shadow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Task Completed \n ${_taskDetail!.completionDate}",
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : _buildBottomButtons(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab() {
    final progressDetails = _taskDetail!.progressDetails;

    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Progress Update Button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                // TODO: Add progress update
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+ Update',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Progress Details
          if (progressDetails.isEmpty)
            _buildEmptyState('No progress updates available')
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: Column(
                children: progressDetails.asMap().entries.map((entry) {
                  final index = entry.key;
                  final progress = entry.value;
                  final isLast = index == progressDetails.length - 1;

                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildProgressCardContent(progress),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(context).colorScheme.outline,
                          indent: 0,
                          endIndent: 0,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildInstructionsTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Instruction Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showAddDataModal('instruction', 'Instruction'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ Instruction',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Instructions List
          _taskDetail?.instructions.isEmpty == true
              ? _buildEmptyState('No any instructions')
              : _buildAllInstructionsList(),
        ],
      ),
    );
  }

  Widget _buildRemarksTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Remark Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showAddDataModal('remark', 'Remark'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ Remark',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Remarks List
          _taskDetail?.remarks.isEmpty == true
              ? _buildEmptyState('No remarks in this task')
              : _buildAllRemarksList(),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Comment Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showAddDataModal('comment', 'Comment'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ Comment',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Comments List
          _taskDetail?.comments.isEmpty == true
              ? _buildEmptyState('No any comment')
              : _buildAllCommentsList(),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Photos Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _isUploadingImages ? null : _pickAndUploadImages,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isUploadingImages
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploadingImages
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Uploading...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Add Photos',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Images Grid
          _taskDetail?.images.isEmpty == true
              ? _buildEmptyState('No photos available')
              : _buildAllImagesGrid(),
        ],
      ),
    );
  }

  Widget _buildAttachmentsTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Attachment Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _isUploadingAttachments
                    ? null
                    : _pickAndUploadAttachments,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isUploadingAttachments
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploadingAttachments
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Uploading...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '+ New',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Attachments Grid
          _taskDetail?.allAttachments.isEmpty == true
              ? _buildEmptyState('No attachments available')
              : _buildAllAttachmentsGrid(),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice Notes Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice Notes',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Add voice note
                },
                child: Text(
                  '+ New',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Voice Notes Content
          if (_taskDetail?.voiceNotes.isEmpty == true)
            _buildEmptyState('No voice notes available')
          else
            _buildVoiceNotesList(),
        ],
      ),
    );
  }

  Widget _buildQCTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QC Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quality Check',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Add QC
                },
                child: Text(
                  '+ New',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // QC Content
          if (_taskDetail?.qualityChecks.isEmpty == true)
            _buildEmptyState('No QC data available')
          else
            _buildQCData(),
        ],
      ),
    );
  }

  Widget _buildUnitSection() {
    final hasProgress = _taskDetail?.progressDetails.isNotEmpty == true;
    final isTaskCompleted = ValidationUtils.isTaskDetailCompleted(_taskDetail!);
    final totalWork = _taskDetail?.totalWork ?? 0;
    final totalWorkDone = _taskDetail?.totalWorkDone ?? 0;
    final workLeft = totalWork - totalWorkDone;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unit For Work Updates',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),

          // Work Progress Row
          if (totalWork > 0)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  // Total Work
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Work',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$totalWork ${_selectedUnit?.symbol ?? _taskDetail?.unit ?? '%'}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(width: 1, height: 40, color: AppColors.borderColor),

                  // Work Done
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Work Done',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$totalWorkDone ${_selectedUnit?.symbol ?? _taskDetail?.unit ?? '%'}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(width: 1, height: 40, color: AppColors.borderColor),

                  // Work Left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Work Left',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$workLeft ${_selectedUnit?.symbol ?? _taskDetail?.unit ?? '%'}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: workLeft > 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 12),

          // Unit Dropdown
          GestureDetector(
            onTap: _isLoadingUnits || hasProgress ? null : (isTaskCompleted ? _showTaskCompletedWarning : _showUnitPicker),
                          child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (hasProgress || isTaskCompleted)
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (hasProgress || isTaskCompleted)
                        ? AppColors.borderColor.withOpacity(0.5)
                        : AppColors.borderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedUnit?.symbol ?? _taskDetail?.unit ?? '%',
                      style: AppTypography.bodyMedium.copyWith(
                        color: (hasProgress || isTaskCompleted)
                                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Spacer(),
                    if (_isLoadingUnits)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    else if (hasProgress || isTaskCompleted)
                      Icon(
                        Icons.lock,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        size: 16,
                      )
                    else
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionSection() {
    final isTaskCompleted = ValidationUtils.isTaskDetailCompleted(_taskDetail!);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Pending From
          GestureDetector(
            onTap: (isTaskCompleted || !ValidationUtils.canChangeDecisionPendingFrom(_taskDetail!))
                ? (isTaskCompleted ? _showTaskCompletedWarning : null)
                : _showDecisionSelectionModal,
            child: Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                SizedBox(width: 8),
                Text(
                  '${_taskDetail?.categoryName ?? 'Category'} Pending From',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ' - ',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _buildDecisionPendingFromText(),
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            color: (isTaskCompleted || !ValidationUtils.canChangeDecisionPendingFrom(
                              _taskDetail!,
                            ))
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!isTaskCompleted && ValidationUtils.canChangeDecisionPendingFrom(
                        _taskDetail!,
                      ))
                        Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Category Due From
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                '${_taskDetail?.categoryName ?? 'Category'} Due From',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' - ',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  _taskDetail?.completionDate ?? 'N/A',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    final progressDetails = _taskDetail!.progressDetails;
    final isTaskCompleted = ValidationUtils.isTaskDetailCompleted(_taskDetail!);
    final maxVisible = 2; // Show max 2 progress entries
    final visibleProgress = progressDetails.take(maxVisible).toList();
    final hasMore = progressDetails.length > maxVisible;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Timeline',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Add instruction
                  },
                  child: Text(
                    isTaskCompleted ? 'Task is completed' : '+ Update',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isTaskCompleted ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderColor),

          // Card Content
          Padding(
            padding: EdgeInsets.all(16),
            child: progressDetails.isEmpty
                ? _buildEmptyState('No progress updates available')
                : Column(
                    children: visibleProgress.asMap().entries.map((entry) {
                      final index = entry.key;
                      final progress = entry.value;
                      final isLast = index == visibleProgress.length - 1;

                      return Column(
                        children: [
                          _buildProgressCardContent(progress),
                          if (!isLast) ...[
                            SizedBox(height: 16),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.borderColor,
                              indent: 0,
                              endIndent: 0,
                            ),
                            SizedBox(height: 16),
                          ],
                        ],
                      );
                    }).toList(),
                  ),
          ),
          if (hasMore)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // Switch to Timeline tab
                    _tabController?.animateTo(1); // Timeline tab index
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0, bottom: 10),
                    child: Text(
                      'View More',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCardContent(ProgressDetailModel progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            Icon(Icons.bar_chart, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              'Progress update - ${progress.workDone ?? '0'}${_taskDetail?.unit ?? '%'}',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // Task updated date
        Text(
          'Task updated at : ${_formatDate(progress.createdAt)}',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),

        // Work details row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Done',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    progress.workDone ?? '0',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skilled',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    progress.skillWorkers ?? '0',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unskilled',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    progress.unskillWorkers ?? '0',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Material Used',
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Used Materials Section (if any materials were used)
        if (progress.usedMaterial.isNotEmpty) ...[
          SizedBox(height: 5,),
          _buildUsedMaterialsSection(progress.usedMaterial),
        ],

        SizedBox(height: 16),

        // Updated by
        Text(
          'Updated By',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4),
        Text(
          progress.user.displayName,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUsedMaterialsSection(List<UsedMaterialModel> usedMaterials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        ...usedMaterials.map((material) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
        (material.material.specification != null) ? '${material.material.specification}' : "Material",
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              ' * ${material.quantity} ${material.material.unitOfMeasurement}',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildTaskMetadataCard() {
    final catSubId = _taskDetail?.catSubId;
    final isSpecialTask = [2, 3, 4, 6].contains(catSubId);
    final isTaskCompleted = ValidationUtils.isTaskDetailCompleted(_taskDetail!);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Work Category -- Created By
          Row(
            children: [
              Expanded(
                child: _buildMetadataColumn(
                  'Work Category',
                  _taskDetail?.categoryName ?? 'N/A',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetadataColumn(
                  'Created By',
                  _taskDetail?.createdUser.displayName ?? 'N/A',
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Row 2: Date fields (different for special tasks)
          Row(
            children: [
              Expanded(
                child: _buildClickableDateColumn(
                  isSpecialTask ? 'Asking Date' : 'Start Date',
                  _taskDetail?.startDate,
                  isTaskCompleted ? _showTaskCompletedWarning : _showStartDatePicker,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildClickableDateColumn(
                  isSpecialTask ? 'Requirement Date' : 'End Date',
                  _taskDetail?.endDate,
                  isTaskCompleted ? _showTaskCompletedWarning : _showEndDatePicker,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Row 3: Tag -- Total Price
          Row(
            children: [
              Expanded(child: _buildTagColumn(isTaskCompleted)),
              SizedBox(width: 16),
              Expanded(
                child:                 GestureDetector(
                  onTap: isTaskCompleted ? _showTaskCompletedWarning : () => _showAddDataModal('price', 'Price'),
                  child: _buildMetadataColumn(
                    'Total Price',
                    _taskDetail?.totalPrice ?? '+ Add Price',
                    isAction: !isTaskCompleted && (_taskDetail?.totalPrice == null),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Row 4: Assign To
          Row(
            children: [
              Expanded(
                child:                 GestureDetector(
                  onTap: isTaskCompleted ? _showTaskCompletedWarning : _showUserAssignmentModal,
                  child: _buildMetadataColumn(
                    'Assign To',
                    _buildAssignToText(),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildTagColumn([bool isTaskCompleted = false]) {
    final tags = _taskDetail?.tagsData ?? [];

    if (tags.isEmpty) {
      return GestureDetector(
        onTap: isTaskCompleted ? _showTaskCompletedWarning : _showTagSelectionModal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tag',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '+ Add Tag',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                color: isTaskCompleted ? AppColors.textSecondary : AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isTaskCompleted ? _showTaskCompletedWarning : _showTagSelectionModal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tag',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            tags.map((tag) => tag.name).join(', '),
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataColumn(
    String label,
    String value, {
    bool isAction = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            color: isAction ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
            fontWeight: isAction ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableDateColumn(
    String label,
    String? dateValue,
    VoidCallback? onTap,
  ) {
    String displayValue = 'N/A';

    if (dateValue != null && dateValue != 'N/A') {
      try {
        // Check if it's already in dd-MM-yyyy format
        if (dateValue.contains('-') && dateValue.length == 10) {
          final parts = dateValue.split('-');
          if (parts.length == 3) {
            if (parts[0].length == 4) {
              // It's in yyyy-MM-dd format, convert to dd-MM-yyyy
              displayValue = DatePickerUtils.formatDate(
                dateValue,
                fromFormat: 'yyyy-MM-dd',
                toFormat: 'dd-MM-yyyy',
              );
            } else if (parts[0].length == 2) {
              // It's already in dd-MM-yyyy format
              displayValue = dateValue;
            } else {
              // Unknown format, show as is
              displayValue = dateValue;
            }
          } else {
            displayValue = dateValue;
          }
        } else {
          // Not in expected format, show as is
          displayValue = dateValue;
        }
      } catch (e) {
        displayValue = dateValue;
      }
    }

    return GestureDetector(
      onTap: _isUpdatingDates ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                displayValue,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: _isUpdatingDates
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isUpdatingDates)
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildAssignToText() {
    final assignTo = _taskDetail?.assignTo;
    if (assignTo == null || assignTo.isEmpty) {
      return 'Not assigned';
    }

    // Get current logged-in user ID
    final currentUserId = AuthService.currentUser?.id;

    // Parse assigned user IDs
    final assignedUserIds = assignTo
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((id) => id > 0)
        .toList();

    if (assignedUserIds.isEmpty) {
      return 'Not assigned';
    }

    // Find user names from site users (preferred) or all users (fallback)
    List<SiteUserModel> assignedUsers = _siteUsers
        .where((user) => assignedUserIds.contains(user.id))
        .toList();

    // If not found in site users, try all users as fallback
    if (assignedUsers.isEmpty) {
      assignedUsers = _availableUsers
          .where((user) => assignedUserIds.contains(user.id))
          .toList();
    }

    // If users are not loaded yet, show IDs as fallback
    if (_siteUsers.isEmpty && _availableUsers.isEmpty) {
      if (assignedUserIds.length == 1) {
        return 'User ${assignedUserIds.first}';
      } else {
        return '${assignedUserIds.length} users assigned';
      }
    }

    // If it's a single user
    if (assignedUsers.length == 1) {
      return assignedUsers.first.fullName;
    }

    // If multiple users, check if current user is assigned
    if (currentUserId != null && assignedUserIds.contains(currentUserId)) {
      return 'You + ${assignedUsers.length - 1}';
    } else if (assignedUsers.isNotEmpty) {
      return '${assignedUsers.first.fullName} + ${assignedUsers.length - 1}';
    } else {
      return '${assignedUserIds.length} users assigned';
    }
  }

  String _buildDecisionPendingFromText() {
    final decisionByAgency = _taskDetail?.decisionByAgency;
    if (decisionByAgency == null || decisionByAgency.isEmpty) {
      return 'N/A';
    }

    // If decision_by_agency is "Other", show decision_pending_other
    if (decisionByAgency.toLowerCase() == 'other') {
      return _taskDetail?.decisionPendingOther ?? 'N/A';
    }

    // Otherwise show the agency name
    return decisionByAgency;
  }

  Widget _buildSurveyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Questions
        ..._surveyQuestions
            .map((question) => _buildQuestionItem(question))
            .toList(),
      ],
    );
  }

  Widget _buildQuestionItem(Question question) {
    // Create a persistent state holder for this question
    final stateHolder = _getQuestionStateHolder(question.id);
    
    return StatefulBuilder(
      builder: (context, setLocalState) {
        // Use the persistent state holder
        bool isRemarksExpanded = stateHolder.isRemarksExpanded;
        
        return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Question + Yes/No options
          Row(
            children: [
              // Question badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q${question.id}',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Question text
              Expanded(
                child: Text(
                  question.question,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Yes/No buttons
              Row(
                children: [
                  // Yes button
                  GestureDetector(
                    onTap: () {
                      setLocalState(() {
                        question.answer = 'Yes';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            question.answer == 'Yes' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: question.answer == 'Yes' ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 15,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Yes',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 13,
                              color: question.answer == 'Yes' ? Colors.green : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // No button
                  GestureDetector(
                    onTap: () {
                      setLocalState(() {
                        question.answer = 'No';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            question.answer == 'No' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: question.answer == 'No' ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 15,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'No',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 14,
                              color: question.answer == 'No' ? Colors.red : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

              // Expandable Remarks Section
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  log("Tapped == ");
                  setLocalState(() {
                    stateHolder.isRemarksExpanded = !stateHolder.isRemarksExpanded;
                  });
                  log("Tapped == ${stateHolder.isRemarksExpanded}");
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Remarks (Optional)',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        isRemarksExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Remarks TextField
              if (isRemarksExpanded) ...[
                SizedBox(height: 8),
                TextFormField(
                  initialValue: question.remark,
                  maxLines: 3,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    hintText: 'Add any additional remarks...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onChanged: (value) {
                    setLocalState(() {
                      question.remark = value;
                    });
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }


  String _getAppBarTitle() {
    if (_taskDetail == null) return 'Task Details';

    final taskName = _taskDetail!.name;
    final progress = _taskDetail!.progress;

    if (progress != null) {
      return '$taskName - $progress%';
    }

    return taskName;
  }

  Color _getStatusColor() {
    switch (_taskDetail?.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Theme.of(context).colorScheme.primary;
      case 'complete':
        return Colors.green;
      case 'overdue':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQCData() {
    return Column(
      children: _taskDetail!.qualityChecks.map((qc) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.textWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QC Check: ${qc.checkType}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              ...qc.items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.isPassed ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: item.isPassed
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRemarksList() {
    final remarks = _taskDetail!.remarks;
    final maxVisible = 3; // Show max 3 in Details tab
    final visibleRemarks = remarks.take(maxVisible).toList();
    final hasMore = remarks.length > maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visibleRemarks.map((remark) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: remark.user.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: ' ${_formatDate(remark.createdAt)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                "- ${remark.remark}",
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 8),
            ],
          );
        }).toList(),
        if (hasMore)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  // Switch to Remarks tab
                  _tabController?.animateTo(3); // Remarks tab index
                },
                child: Text(
                  'View More',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInstructionsList() {
    final instructions = _taskDetail!.instructions;
    final maxVisible = 3; // Show max 3 in Details tab
    final visibleInstructions = instructions.take(maxVisible).toList();
    final hasMore = instructions.length > maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visibleInstructions.map((instruction) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: instruction.user.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: ' ${_formatDate(instruction.createdAt)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                "- ${instruction.instruction}",
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 8),
            ],
          );
        }),
        if (hasMore)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  // Switch to Instructions tab
                  _tabController?.animateTo(2); // Instructions tab index
                },
                child: Text(
                  'View More',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCommentsList() {
    final comments = _taskDetail!.comments;
    final maxVisible = 3; // Show max 3 in Details tab
    final visibleComments = comments.take(maxVisible).toList();
    final hasMore = comments.length > maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visibleComments.map((comment) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: comment.user.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: ' ${_formatDate(comment.createdAt)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                "- ${comment.comment}",
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 8),
            ],
          );
        }),
        if (hasMore)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  // Switch to Comments tab
                  _tabController?.animateTo(4); // Comments tab index
                },
                child: Text(
                  'View More',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImagesGrid() {
    final allImages = _taskDetail!.allImages;
    final maxVisible = 8; // Show exactly 8 images, then +N
    final visibleImages = allImages.take(maxVisible).toList();
    final remainingCount = allImages.length - maxVisible + 1;

    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1.0,
        ),
        itemCount: remainingCount > 0 ? maxVisible : visibleImages.length,
        itemBuilder: (context, index) {
          // Show +N indicator on the last visible item if there are more images
          if (remainingCount > 0 && index == maxVisible - 1) {
            return GestureDetector(
              onTap: () {
                // Switch to Photos tab
                _tabController?.animateTo(5); // Photos tab index
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.textSecondary.withOpacity(0.8),
                  border: Border.all(color: AppColors.borderColor, width: 1),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          final image = visibleImages[index];
          return GestureDetector(
            onTap: () => _openFullScreenImageViewer(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isLocalImage(image.imagePath)
                    ? Image.file(
                        File(image.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.borderColor,
                            child: Icon(
                              Icons.broken_image,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      )
                    : Image.network(
                        image.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.borderColor,
                            child: Icon(
                              Icons.broken_image,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllImagesGrid() {
    final allImages = _taskDetail!.allImages;

    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          final image = allImages[index];
          return GestureDetector(
            onTap: () => _openFullScreenImageViewer(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isLocalImage(image.imagePath)
                    ? Image.file(
                        File(image.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.borderColor,
                            child: Icon(
                              Icons.broken_image,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      )
                    : Image.network(
                        image.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.borderColor,
                            child: Icon(
                              Icons.broken_image,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachmentsList() {
    final allAttachments = _taskDetail!.allAttachments;
    final maxVisible = 8; // Show exactly 8 attachments, then +N
    final visibleAttachments = allAttachments.take(maxVisible).toList();
    final remainingCount = allAttachments.length - maxVisible + 1;

    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1.0,
        ),
        itemCount: remainingCount > 0 ? maxVisible : visibleAttachments.length,
        itemBuilder: (context, index) {
          // Show +N indicator on the last visible item if there are more attachments
          if (remainingCount > 0 && index == maxVisible - 1) {
            return GestureDetector(
              onTap: () {
                // Switch to Attachments tab
                _tabController?.animateTo(6); // Attachments tab index
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.textSecondary.withOpacity(0.8),
                  border: Border.all(color: AppColors.borderColor, width: 1),
                ),
                child: Center(
                  child: Text(
                    '+${remainingCount}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          final attachment = visibleAttachments[index];
          return GestureDetector(
            onTap: () => _openAttachmentViewer(attachment),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceColor,
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getAttachmentIcon(attachment),
                  SizedBox(height: 4),
                  Text(
                    attachment.fileExtension.toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllAttachmentsGrid() {
    final allAttachments = _taskDetail!.allAttachments;

    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: allAttachments.length,
        itemBuilder: (context, index) {
          final attachment = allAttachments[index];
          return GestureDetector(
            onTap: () => _openAttachmentViewer(attachment),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceColor,
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getAttachmentIcon(attachment),
                  SizedBox(height: 4),
                  Text(
                    attachment.fileExtension.toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllInstructionsList() {
    final instructions = _taskDetail!.instructions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: instructions.map((instruction) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: instruction.user.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: ' ${_formatDate(instruction.createdAt)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              "- ${instruction.instruction}",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 15),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAllRemarksList() {
    final remarks = _taskDetail!.remarks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: remarks.map((remark) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: remark.user.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: ' ${_formatDate(remark.createdAt)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              "- ${remark.remark}",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 15),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAllCommentsList() {
    final comments = _taskDetail!.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: comments.map((comment) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: comment.user.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: ' ${_formatDate(comment.createdAt)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              "- ${comment.comment}",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 15),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildVoiceNotesList() {
    return Column(
      children: _taskDetail!.voiceNotes.map((voiceNote) {
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.textWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.mic, size: 20, color: AppColors.primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voiceNote,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () {
                  // TODO: Handle play
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===== SIMPLE SECTION BUILDERS FOR DETAILS TAB =====

  Widget _buildInstructionsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Instructions',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddDataModal('instruction', 'Instruction'),
                  child: Text(
                    '+ Instruction',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderColor),
          // Section Content
          Padding(
            padding: EdgeInsets.all(16),
            child: _taskDetail?.instructions.isEmpty == true
                ? _buildEmptyState('No any instructions')
                : _buildInstructionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remarks',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddDataModal('remark', 'Remark'),
                  child: Text(
                    '+ Remark',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderColor),
          // Section Content
          Padding(
            padding: EdgeInsets.all(16),
            child: _taskDetail?.remarks.isEmpty == true
                ? _buildEmptyState('No remarks in this task')
                : _buildRemarksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddDataModal('comment', 'Comment'),
                  child: Text(
                    '+ Comment',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderColor),
          // Section Content
          Padding(
            padding: EdgeInsets.all(16),
            child: _taskDetail?.comments.isEmpty == true
                ? _buildEmptyState('No any comment')
                : _buildCommentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCard() {
    final isTaskCompleted = ValidationUtils.isTaskDetailCompleted(_taskDetail!);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.image, size: 18, color: AppColors.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Photos',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _isUploadingImages ? null : _pickAndUploadImages,
                  child: _isUploadingImages
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Uploading...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Add Photos',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: EdgeInsets.all(16),
            child: _taskDetail?.images.isEmpty == true
                ? _buildEmptyState('No photos available')
                : _buildImagesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Attachments',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _isUploadingAttachments
                      ? null
                      : _pickAndUploadAttachments,
                  child: _isUploadingAttachments
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Uploading...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '+ New',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: EdgeInsets.all(16),
            child: _taskDetail?.allAttachments.isEmpty == true
                ? _buildEmptyState('No attachments available')
                : _buildAttachmentsList(),
          ),
        ],
      ),
    );
  }

  // Open full screen image viewer
  void _openFullScreenImageViewer(int initialIndex) {
    if (_taskDetail?.allImages.isEmpty == true) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: _taskDetail!.allImages,
          initialIndex: initialIndex,
          onImageDeleted: _handleImageDeleted,
          getCurrentImages: () =>
              _taskDetail?.allImages ??
              [], // Pass callback to get current images
        ),
      ),
    );
  }

  // Handle image deletion callback
  void _handleImageDeleted(int deletedIndex) {
    // Update the image list locally without full reload
    if (_taskDetail != null) {
      setState(() {
        // Remove the deleted image from the list
        final allImages = _taskDetail!.allImages;
        if (deletedIndex < allImages.length) {
          final deletedImage = allImages[deletedIndex];

          // Remove from task images if it's a task image
          if (deletedImage.source == ImageSource.taskImage) {
            _taskDetail = _taskDetail!.copyWith(
              images: _taskDetail!.images
                  .where((img) => img.id != deletedImage.id)
                  .toList(),
            );
          }
          // For progress images, we'll need to reload since ProgressDetailModel doesn't have copyWith
          else if (deletedImage.source == ImageSource.progressImage) {
            // Reload only for progress images
            _loadTaskDetails();
            return;
          }
        }
      });

      // Force rebuild of the viewer by updating the task detail reference
      _taskDetail = _taskDetail!.copyWith(
        id: _taskDetail!.id, // This forces a new reference
      );
    }
  }

  // Date formatting utility
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

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

      final month = months[date.month - 1];
      final day = date.day;
      final year = date.year;

      return '$month $day, $year';
    } catch (e) {
      return dateString;
    }
  }

  // Attachment icon utility
  Widget _getAttachmentIcon(UnifiedAttachmentModel attachment) {
    final extension = attachment.fileExtension.toLowerCase().trim();
    
    // Debug logging
    print('Attachment icon debug: ${attachment.debugInfo}');
    print('Extension for icon: "$extension", length: ${extension.length}');

    // Use if-else instead of switch for more robust comparison
    if (extension == 'pdf') {
      print('Returning PDF icon');
      return Icon(Icons.picture_as_pdf, size: 24, color: Colors.red);
    } else if (extension == 'doc' || extension == 'docx') {
      return Icon(Icons.description, size: 24, color: Colors.blue);
    } else if (extension == 'xls' || extension == 'xlsx') {
      return Icon(Icons.table_chart, size: 24, color: Colors.green);
    } else if (extension == 'ppt' || extension == 'pptx') {
      return Icon(Icons.slideshow, size: 24, color: Colors.orange);
    } else if (extension == 'txt') {
      return Icon(Icons.text_snippet, size: 24, color: Colors.grey);
    } else if (extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'gif' || extension == 'bmp') {
      return Icon(Icons.image, size: 24, color: Colors.purple);
    } else if (extension == 'mp4' || extension == 'avi' || extension == 'mov' || extension == 'wmv') {
      return Icon(Icons.video_file, size: 24, color: Colors.red);
    } else if (extension == 'mp3' || extension == 'wav' || extension == 'aac') {
      return Icon(Icons.audio_file, size: 24, color: Colors.blue);
    } else if (extension == 'zip' || extension == 'rar' || extension == '7z') {
      return Icon(Icons.archive, size: 24, color: Colors.orange);
    } else {
      print('Using default icon for extension: "$extension"');
      return Icon(
        Icons.insert_drive_file,
        size: 24,
        color: AppColors.primaryColor,
      );
    }
  }

  // Open attachment viewer
  void _openAttachmentViewer(UnifiedAttachmentModel attachment) {
    final extension = attachment.fileExtension.toLowerCase();
    
    // Check if file type is supported for inline viewing
    final supportedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif', 'bmp'];
    
    if (supportedExtensions.contains(extension)) {
      // Open in FileViewer for inline viewing
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FileViewer(
            fileUrl: attachment.attachmentPath,
            fileName: attachment.fileName,
            fileExtension: attachment.fileExtension,
          ),
        ),
      );
    } else {
      // Open in AttachmentViewer for other file types
      final allAttachments = _taskDetail!.allAttachments;
      
      // Debug logging
      print('Opening attachment viewer:');
      print('Attachment to find: ${attachment.debugInfo}');
      print('Total attachments: ${allAttachments.length}');
      
      // Find attachment by comparing properties instead of using indexOf
      int initialIndex = -1;
      for (int i = 0; i < allAttachments.length; i++) {
        final listAttachment = allAttachments[i];
        if (listAttachment.attachmentPath == attachment.attachmentPath && 
            listAttachment.fileName == attachment.fileName) {
          initialIndex = i;
          break;
        }
      }
      
      print('Initial index found: $initialIndex');
      
      if (initialIndex == -1) {
        print('Attachment not found in list!');
        // List all attachments for debugging
        for (int i = 0; i < allAttachments.length; i++) {
          print('Attachment $i: ${allAttachments[i].debugInfo}');
        }
        SnackBarUtils.showError(context, message: 'Attachment not found');
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AttachmentViewer(
            attachments: allAttachments,
            initialIndex: initialIndex,
            onAttachmentDeleted: _handleAttachmentDeleted,
          ),
        ),
      );
    }
  }

  // Handle attachment deletion callback
  void _handleAttachmentDeleted(int deletedIndex) {
    // Update the attachment list locally without full reload
    if (_taskDetail != null) {
      setState(() {
        final allAttachments = _taskDetail!.allAttachments;
        if (deletedIndex < allAttachments.length) {
          final deletedAttachment = allAttachments[deletedIndex];

          // Remove from task attachments if it's a task attachment
          if (deletedAttachment.source == AttachmentSource.taskAttachment) {
            _taskDetail = _taskDetail!.copyWith(
              attachments: _taskDetail!.attachments
                  .where((attachment) => attachment != deletedAttachment.attachmentPath)
                  .toList(),
            );
          }
          // For progress attachments, we'll need to reload since ProgressDetailModel doesn't have copyWith
          else if (deletedAttachment.source == AttachmentSource.progressAttachment) {
            // Reload only for progress attachments
            _loadTaskDetails();
            return;
          }
        }
      });

      // Force rebuild of the viewer by updating the task detail reference
      _taskDetail = _taskDetail!.copyWith(
        id: _taskDetail!.id, // This forces a new reference
      );
    }
  }



  // Check if image is local file or network URL
  bool _isLocalImage(String imagePath) {
    return imagePath.startsWith('/') ||
        imagePath.startsWith('file://') ||
        !imagePath.startsWith('http');
  }

  // Site Survey Helper Methods
  void _initializeSurveyQuestions() {
    _surveyQuestions = [
      Question(
        id: 1,
        question: "ANY ACCIDENTS ON SITE TODAY?",
        remark: _getRemark(0, 'remark1'),
        answer: _getAnswer(0, 'answer1'),
      ),
      Question(
        id: 2,
        question: "ANY SCHEDULES DELAY OCCURS?",
        remark: _getRemark(0, 'remark2'),
        answer: _getAnswer(0, 'answer2'),
      ),
      Question(
        id: 3,
        question: "DID WEATHER CAUSES ANY DELAY?",
        remark: _getRemark(0, 'remark3'),
        answer: _getAnswer(0, 'answer3'),
      ),
      Question(
        id: 4,
        question: "ANY VISITORS ON SITE?",
        remark: _getRemark(0, 'remark4'),
        answer: _getAnswer(0, 'answer4'),
      ),
      Question(
        id: 5,
        question: "ANY AREA THAT CAN'T BE WORKED ON?",
        remark: _getRemark(0, 'remark5'),
        answer: _getAnswer(0, 'answer5'),
      ),
    ];
    _previousAnswers = _questionsToListOfMaps(_surveyQuestions);
  }

  String _getRemark(int index, String remarkField) {
    if (_taskDetail?.progressDetails.isNotEmpty == true &&
        _taskDetail!.progressDetails[index].taskQuestions.isNotEmpty) {
      final taskQuestion = _taskDetail!.progressDetails[index].taskQuestions[0];
      switch (remarkField) {
        case 'remark1':
          return taskQuestion.remark1 ?? "";
        case 'remark2':
          return taskQuestion.remark2 ?? "";
        case 'remark3':
          return taskQuestion.remark3 ?? "";
        case 'remark4':
          return taskQuestion.remark4 ?? "";
        case 'remark5':
          return taskQuestion.remark5 ?? "";
        default:
          return "";
      }
    }
    return "";
  }

  String _getAnswer(int index, String answerField) {
    if (_taskDetail?.progressDetails.isNotEmpty == true &&
        _taskDetail!.progressDetails[index].taskQuestions.isNotEmpty) {
      final taskQuestion = _taskDetail!.progressDetails[index].taskQuestions[0];
      switch (answerField) {
        case 'answer1':
          return taskQuestion.answer1 ?? "";
        case 'answer2':
          return taskQuestion.answer2 ?? "";
        case 'answer3':
          return taskQuestion.answer3 ?? "";
        case 'answer4':
          return taskQuestion.answer4 ?? "";
        case 'answer5':
          return taskQuestion.answer5 ?? "";
        default:
          return "";
      }
    }
    return "";
  }

  bool _validateSurveyAnswers() {
    List<int> unansweredQuestions = [];

    for (var question in _surveyQuestions) {
      if (question.answer == null || question.answer!.isEmpty) {
        unansweredQuestions.add(question.id);
      }
    }

    if (unansweredQuestions.isNotEmpty) {
      setState(() {
        _surveyErrorMessage =
            "Please answer questions: ${unansweredQuestions.join(', ')}";
      });
      return false;
    }

    setState(() {
      _surveyErrorMessage = null;
    });
    return true;
  }

  Map<String, dynamic> _questionsToListOfMaps(List<Question> questions) {
    Map<String, dynamic> combinedMap = {};
    for (var question in questions) {
      combinedMap['question_${question.id}'] = question.question;
      combinedMap['answer_${question.id}'] = question.answer ?? '';
      combinedMap['remark_${question.id}'] = question.remark;
    }

    return combinedMap;
  }

  bool _hasSurveyChanges() {
    Map<String, dynamic> currentAnswers = _questionsToListOfMaps(
      _surveyQuestions,
    );
    return !mapEquals(_previousAnswers, currentAnswers);
  }

  Future<void> _submitSurvey() async {
    if (!_validateSurveyAnswers()) {
      return;
    }

    // Check if user made any changes
    if (!_hasSurveyChanges()) {
      SnackBarUtils.showError(
        context,
        message: 'Please make changes to the survey before submitting',
      );
      return;
    }

    setState(() {
      _isSubmittingSurvey = true;
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

      final questionAnswer = _questionsToListOfMaps(_surveyQuestions);

      final response = await ApiService.updateProgress(
        apiToken: apiToken,
        taskId: widget.task.id,
        workDone: "100", // Site survey is always 100% complete
        questionAnswer: questionAnswer,
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Survey submitted successfully',
        );

        // Update the parent screen with the updated task data
        if (widget.onTaskUpdated != null) {
          final updatedTask = widget.task.copyWith(
            progress: 100, // Site survey is always 100% complete
            status: 'complete', // Update status to complete
          );

          widget.onTaskUpdated!(updatedTask);
        } else {}

        _loadTaskDetails(); // Reload to get updated data
      } else {
        SnackBarUtils.showError(
          context,
          message: response?.message ?? 'Failed to submit survey',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to submit survey: $e');
    } finally {
      setState(() {
        _isSubmittingSurvey = false;
      });
    }
  }


  Future<void> _handleUpdateTask() async {
    // Check if task is already completed (progress = 100%)
    if (widget.task.progressPercentage >= 100) {
      SnackBarUtils.showSuccess(context, message: 'Task already completed');
      return;
    }
    
    // Check if this is a supported task type (cat_sub_id = 2,3,4,5,6)
    final supportedTaskTypes = [2, 3, 4, 5, 6];
    if (supportedTaskTypes.contains(_taskDetail?.catSubId)) {
      // Check update permissions for simple tasks (cat_sub_id 2,3,4,6)
      if (!ValidationUtils.canUpdateTask(widget.task)) {
        SnackBarUtils.showError(context, message: "You don't have permission to update this task");
        return;
      }
      
      // Navigate to Update Task Screen
      final result = await NavigationUtils.push(context, UpdateTaskScreen(
        task: widget.task,
        onTaskUpdated: widget.onTaskUpdated,
      ));
      
      // If update was successful, reload task details and show success message
      if (result != null && result is String) {
        // Reload task details to get the latest data from server
        _loadTaskDetails();
        
        // Show success message after a brief delay to ensure UI is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showSuccess(context, message: result);
        });
      }
    } else {
      // For unsupported task types, show appropriate message
      SnackBarUtils.showError(context, message: 'Update functionality not available for this task type');
    }
  }

  Widget _buildBottomButtons() {
    // Check if this is a simple task (cat_sub_id 2,3,4,6)
    final simpleTaskCategories = ['decision', 'drawing', 'quotation', 'selection'];
    final isSimpleTask = simpleTaskCategories.contains(widget.task.categoryName.toLowerCase());
    
    if (isSimpleTask) {
      // For simple tasks, show Accept button if user has permission
      if (ValidationUtils.canAcceptTask(widget.task)) {
        return Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: () {
                  _handleAcceptTask();
                },
                text: 'Accept Task',
                backgroundColor: Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                onPressed: () {
                  _handleUpdateTask();
                },
                text: 'Update Task',
              ),
            ),
          ],
        );
      } else {
        // User doesn't have permission to accept, only show update button
        return CustomButton(
          onPressed: () {
            _handleUpdateTask();
          },
          text: 'Update Task',
        );
      }
    } else {
      // For non-simple tasks, only show update button
      return CustomButton(
        onPressed: () {
          _handleUpdateTask();
        },
        text: 'Update Task',
      );
    }
  }

  Future<void> _handleAcceptTask() async {
    // Check if there is any progress for this task
    if (_taskDetail?.progressDetails.isEmpty ?? true) {
      SnackBarUtils.showError(context, message: 'There is no any update for this task yet');
      return;
    }

    // Controllers for the form
    final remarkController = TextEditingController();
    final dateController = TextEditingController();
    
    // Set default date to today
    final today = DateTime.now();
    dateController.text = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

    // Show form dialog
    final formData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Task'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date picker
              GestureDetector(
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: today,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (selectedDate != null) {
                    dateController.text = '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateController.text,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Remark text field
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remark *',
                  hintText: 'Enter remark for accepting this task...',
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
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (remarkController.text.trim().isEmpty) {
                SnackBarUtils.showError(context, message: 'Please enter a remark');
                return;
              }
              Navigator.pop(context, {
                'remark': remarkController.text.trim(),
                'date': dateController.text,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: AppColors.textWhite,
            ),
            child: Text('Accept'),
          ),
        ],
      ),
    );

    if (formData == null) return;

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      // Convert date from DD-MM-YYYY to YYYY-MM-DD format
      final dateParts = formData['date']!.split('-');
      final completionDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

      // Call accept task API
      final response = await ApiService.acceptTask(
        apiToken: apiToken,
        taskId: widget.task.id,
        remark: formData['remark']!,
        completionDate: completionDate,
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(context, message: 'Task accepted successfully');
        
        // Reload task details to get the latest data
        _loadTaskDetails();
        
        // Update parent screen if callback provided
        if (widget.onTaskUpdated != null) {
          final updatedTask = widget.task.copyWith(
            status: 'Complete', // Update status to complete
          );
          widget.onTaskUpdated!(updatedTask);
        }
      } else {
        SnackBarUtils.showError(
          context, 
          message: response?.message ?? 'Failed to accept task'
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to accept task: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTaskCompletedWarning() {
    SnackBarUtils.showInfo(
      context, 
      message: 'Data is not editable after task completed'
    );
  }
}
