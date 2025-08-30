import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/validation_utils.dart';
import '../models/task_model.dart';
import '../screens/task_details_screen.dart';
import '../screens/update_task_screen.dart';
import '../services/auth_service.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final Function(TaskModel)? onTaskUpdated;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onTaskUpdated,
  });

    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to task details when anywhere on card is tapped
        NavigationUtils.push(context, TaskDetailsScreen(
          task: task,
          onTaskUpdated: onTaskUpdated,
        ));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content row
              Row(
                children: [
                  // Percentage block on the left
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPercentageBoxColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${task.progressPercentage.toInt()}%',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          color: _getPercentageBoxColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Task name and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          task.categoryName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _handleUpdateAction(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size(0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'Update',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.surface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          // Navigate to task details
                          NavigationUtils.push(context, TaskDetailsScreen(
                            task: task,
                            onTaskUpdated: onTaskUpdated,
                          ));
                        },
                        child: Text(
                          'View Details >',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Separator line
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                height: 1,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),

              // Assignment status and dates
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment status
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 6),
                      Text(
                        _getAssignDisplayText(),
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  // Show dates based on task type
                  SizedBox(height: 8),
                  Row(
                    children: [
                      // Start Date
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_getStartDateLabel()}: ${task.startDate ?? 'NA'}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isSiteSurveyTask()) ...[
                        SizedBox(width: 12),
                        // End Date
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_getEndDateLabel()}: ${task.endDate ?? 'NA'}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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



  String _getAssignDisplayText() {
    // Type 1: Site Survey - No crew members
    if (_isSiteSurveyTask()) {
      return task.createdByName;
    }
    
    // Use assign list which contains UserModel objects with actual names
    if (task.assign.isEmpty) {
      return 'No assign';
    }
    
    // Get current user ID
    final currentUserId = AuthService.currentUser?.id;
    
    // Check if current user is in the assigned users list
    final isCurrentUserAssigned = currentUserId != null && 
        task.assign.any((user) => user.id == currentUserId);
    
    if (task.assign.length == 1) {
      if (isCurrentUserAssigned) {
        return 'You';
      } else {
        return task.assign.first.displayName;
      }
    }
    
    if (task.assign.length == 2) {
      if (isCurrentUserAssigned) {
        return 'You + 1';
      } else {
        return '${task.assign.first.displayName} + 1';
      }
    }
    
    if (isCurrentUserAssigned) {
      return 'You + ${task.assign.length - 1}';
    } else {
      return '${task.assign.first.displayName} + ${task.assign.length - 1}';
    }
  }

  // Task type helper methods based on category names
  bool _isSiteSurveyTask() {
    return task.categoryName.toLowerCase() == 'site survey';
  }


  bool _isDecisionTask() {
    return task.categoryName.toLowerCase() == 'decision';
  }

  bool _isDrawingTask() {
    return task.categoryName.toLowerCase() == 'drawing';
  }

  bool _isQuotationTask() {
    return task.categoryName.toLowerCase() == 'quotation';
  }

  bool _isSelectionTask() {
    return task.categoryName.toLowerCase() == 'selection';
  }

  bool _isSpecialTask() {
    // Type 3: Special tasks (cat_sub_id = 12,3,4,6 equivalent)
    return _isDecisionTask() || _isDrawingTask() || _isQuotationTask() || _isSelectionTask();
  }

  bool _shouldShowDates() {
    // Show dates for all task types except when both dates are null
    return task.startDate != null || task.endDate != null;
  }

  String _getStartDateLabel() {
    if (_isSiteSurveyTask()) {
      return 'Survey Date';
    } else if (_isSpecialTask()) {
      return 'Asking Date';
    } else {
      return 'Start Date';
    }
  }

  String _getEndDateLabel() {
    if (_isSiteSurveyTask()) {
      return 'Survey Date';
    } else if (_isSpecialTask()) {
      return 'Required Date';
    } else {
      return 'Deadline';
    }
  }

  bool _isOverdue() {
    if (task.endDate == null) return false;
    
    try {
      // Parse the end date (format: DD-MM-YYYY)
      final parts = task.endDate!.split('-');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final endDate = DateTime(year, month, day);
      final today = DateTime.now();
      
      // Task is overdue if end date is in the past and status is not complete
      return endDate.isBefore(today) && !task.isComplete;
    } catch (e) {
      return false;
    }
  }


  Color _getPercentageBoxColor() {
    // If task is overdue, show red regardless of status
    if (_isOverdue()) {
      return const Color(0xFFF44336); // Construction red for overdue
    }
    
    // Otherwise, use status-based colors
    return _getStatusColor();
  }

  Color _getStatusColor() {
    switch (task.status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800); // Construction orange
      case 'active':
        return const Color(0xFF2196F3); // Construction blue
      case 'complete':
        return const Color(0xFF4CAF50); // Construction green
      case 'overdue':
        return const Color(0xFFF44336); // Construction red
      default:
        return const Color(0xFF9E9E9E); // Construction grey
    }
  }

  Future<void> _handleUpdateAction(BuildContext context) async {
    // Check if task is Site Survey
    if (_isSiteSurveyTask()) {
      // Redirect to Survey Page (Task Details Screen)
      NavigationUtils.push(context, TaskDetailsScreen(
        task: task,
        onTaskUpdated: onTaskUpdated,
      ));
      return;
    }
    
    // Check if task is already completed (progress = 100%)
    if (task.progressPercentage >= 100) {
      // Show "Task already completed" message
      SnackBarUtils.showSuccess(context, message: 'Task already completed');
      return;
    }
    
    // Check update permissions for simple tasks (cat_sub_id 2,3,4,6)
    if (!ValidationUtils.canUpdateTask(task)) {
      SnackBarUtils.showError(context, message: "You don't have permission to update this task");
      return;
    }
    
    // For supported task types (cat_sub_id = 2,3,4,5,6), redirect to Update Task Screen
    if (_isSupportedTask()) {
      // Navigate directly to Update Task Screen
      final result = await NavigationUtils.push(context, UpdateTaskScreen(
        task: task,
        onTaskUpdated: onTaskUpdated,
      ));
      
      // Show success message if update was successful
      if (result != null && result is String) {
        SnackBarUtils.showSuccess(context, message: result);
      }
      return;
    }
    
    // For unsupported task types, show error message
    SnackBarUtils.showError(context, message: 'Update functionality not available for this task type');
  }

  bool _isSupportedTask() {
    // Supported task types: cat_sub_id = 2,3,4,5,6
    // This includes: Normal tasks, Decision, Drawing, Quotation, Selection
    // Excludes: Site Survey (handled separately)
    return task.categoryName.toLowerCase() != 'site survey';
  }

}
