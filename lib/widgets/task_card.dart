import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../models/task_model.dart';
import '../screens/task_details_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to task details when anywhere on card is tapped
        NavigationUtils.push(context, TaskDetailsScreen(task: task));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.textWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                            color: AppColors.textPrimary,
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
                            color: AppColors.textSecondary,
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
                          // TODO: Handle update action
                          print('Update task: ${task.name}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.textWhite,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          // Navigate to task details
                          NavigationUtils.push(context, TaskDetailsScreen(task: task));
                        },
                        child: Text(
                          'View Details >',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
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
                color: AppColors.primaryColor.withOpacity(0.2),
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
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        _getAssignDisplayText(),
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
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
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_getStartDateLabel()}: ${task.startDate ?? 'NA'}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
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
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_getEndDateLabel()}: ${task.endDate ?? 'NA'}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
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
      return 'N/A';
    }
    
    if (task.assign.isEmpty) {
      return 'No assign';
    }
    
    if (task.assign.length == 1) {
      return task.assign.first.firstName;
    }
    
    if (task.assign.length == 2) {
      return '${task.assign.first.firstName} + 1';
    }
    
    return '${task.assign.first.firstName} + ${task.assign.length - 1}';
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


}
