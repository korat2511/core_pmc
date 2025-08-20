import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/task_detail_model.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  TaskDetailModel? _taskDetail;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Survey form controllers for cat_sub_id = 1
  final List<TextEditingController> _answerControllers = List.generate(
    5,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _remarkControllers = List.generate(
    5,
    (index) => TextEditingController(),
  );

  // Default survey questions for Site Survey
  final List<String> _defaultQuestions = [
    'ANY ACCIDENTS ON SITE TODAY?',
    'ANY SCHEDULES DELAY OCCURS?',
    'DID WEATHER CAUSES ANY DELAY?',
    'ANY VISITORS ON SITE?',
    'ANY AREA THAT CAN\'T BE WORKED ON?',
  ];

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
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
    super.dispose();
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
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

      // If it's a Site Survey and has existing data, populate the form
      if (taskDetail.isSiteSurvey && taskDetail.progressDetails.isNotEmpty) {
        _populateSurveyForm(taskDetail.progressDetails.first);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(context, message: 'Failed to load task details: $e');
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

  Future<void> _submitSurvey() async {
    if (!_validateSurveyForm()) {
      SnackBarUtils.showError(context, message: 'Please fill all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      // TODO: Implement survey submission API
      // For now, just show success message
      await Future.delayed(Duration(seconds: 2)); // Simulate API call
      
      SnackBarUtils.showSuccess(context, message: 'Survey submitted successfully');
      NavigationUtils.pop(context);
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to submit survey: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
            : _buildTaskContent(),
        floatingActionButton: _taskDetail?.isSiteSurvey == true
            ? FloatingActionButton.extended(
                onPressed: _isSubmitting ? null : _submitSurvey,
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textWhite,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textWhite,
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(
                  _isSubmitting ? 'Saving...' : 'Save Survey',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ));
    }

  Widget _buildTaskContent() {
    if (_taskDetail == null) {
      return Center(
        child: Text(
          'Task details not found',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Handle different task types
    if (_taskDetail!.isSiteSurvey) {
      return _buildSiteSurveyContent();
    } else {
      // For other task types, show placeholder for now
      return _buildPlaceholderContent();
    }
  }

  Widget _buildSiteSurveyContent() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          _buildSurveyForm(),
          
          SizedBox(height: 32),
          
          // Submit Button
          if (_taskDetail?.progressDetails.isEmpty == true)
            CustomButton(
              onPressed: _isSubmitting ? null : _submitSurvey,
              text: _isSubmitting ? 'Submitting...' : 'Submit Survey',
              isLoading: _isSubmitting,
            ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _taskDetail?.name ?? 'Site Survey',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
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
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 1,
                  ),
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
                    color: AppColors.textSecondary,
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
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Survey Date: ${_taskDetail?.startDate ?? 'Not set'}',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Questions
        ...List.generate(5, (index) => _buildQuestionItem(index)),
      ],
    );
  }

  Widget _buildQuestionItem(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            'Question ${index + 1}',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _defaultQuestions[index],
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          
          // Answer
          Text(
            'Answer *',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          // Radio buttons for Yes/No
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    'Yes',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  value: 'Yes',
                  groupValue: _answerControllers[index].text.isEmpty ? null : _answerControllers[index].text,
                  onChanged: (String? value) {
                    setState(() {
                      _answerControllers[index].text = value ?? '';
                    });
                  },
                  activeColor: AppColors.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    'No',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  value: 'No',
                  groupValue: _answerControllers[index].text.isEmpty ? null : _answerControllers[index].text,
                  onChanged: (String? value) {
                    setState(() {
                      _answerControllers[index].text = value ?? '';
                    });
                  },
                  activeColor: AppColors.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Remarks
          Text(
            'Remarks (Optional)',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          TextFormField(
            controller: _remarkControllers[index],
            maxLines: 2,
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
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              hintText: 'Add any additional remarks...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Task Details Screen',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon for ${_taskDetail?.categoryName ?? 'this task type'}',
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    if (_taskDetail == null) return 'Task Details';
    
    final taskName = _taskDetail!.name;
    final progress = _taskDetail!.progress;
    
    if (progress != null) {
      return '$taskName - ${progress}%';
    }
    
    return taskName;
  }

  Color _getStatusColor() {
    switch (_taskDetail?.status.toLowerCase()) {
      case 'pending':
        return AppColors.warningColor;
      case 'active':
        return AppColors.primaryColor;
      case 'complete':
        return AppColors.successColor;
      case 'overdue':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }
}
