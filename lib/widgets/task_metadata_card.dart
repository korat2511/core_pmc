import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/date_picker_utils.dart';
import '../models/task_detail_model.dart';
import '../models/tag_model.dart';
import '../models/site_user_model.dart';

class TaskMetadataCard extends StatelessWidget {
  final TaskDetailModel? taskDetail;
  final List<TagModel> availableTags;
  final List<SiteUserModel> siteUsers;
  final List<int> selectedTagIds;
  final List<int> assignedUserIds;
  final bool isTaskCompleted;
  final bool isUpdatingDates;
  final VoidCallback? onTagTap;
  final VoidCallback? onUserAssignmentTap;
  final VoidCallback? onStartDateTap;
  final VoidCallback? onEndDateTap;
  final VoidCallback? onPriceTap;

  const TaskMetadataCard({
    super.key,
    required this.taskDetail,
    required this.availableTags,
    required this.siteUsers,
    required this.selectedTagIds,
    required this.assignedUserIds,
    required this.isTaskCompleted,
    required this.isUpdatingDates,
    this.onTagTap,
    this.onUserAssignmentTap,
    this.onStartDateTap,
    this.onEndDateTap,
    this.onPriceTap,
  });

  @override
  Widget build(BuildContext context) {
    final catSubId = taskDetail?.catSubId;
    final isSpecialTask = [2, 3, 4, 6].contains(catSubId);

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
                  context,
                  'Work Category',
                  taskDetail?.categoryName ?? 'N/A',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetadataColumn(
                  context,
                  'Created By',
                  taskDetail?.createdUser.displayName ?? 'N/A',
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
                  context,
                  isSpecialTask ? 'Asking Date' : 'Start Date',
                  taskDetail?.startDate,
                  isTaskCompleted ? null : onStartDateTap,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildClickableDateColumn(
                  context,
                  isSpecialTask ? 'Requirement Date' : 'End Date',
                  taskDetail?.endDate,
                  isTaskCompleted ? null : onEndDateTap,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Row 3: Tag -- Total Price
          Row(
            children: [
              Expanded(child: _buildTagColumn(context)),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: isTaskCompleted ? null : onPriceTap,
                  child: _buildMetadataColumn(
                    context,
                    'Total Price',
                    taskDetail?.totalPrice ?? '+ Add Price',
                    isAction: !isTaskCompleted && (taskDetail?.totalPrice == null),
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
                child: GestureDetector(
                  onTap: isTaskCompleted ? null : onUserAssignmentTap,
                  child: _buildMetadataColumn(
                    context,
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

  Widget _buildTagColumn(BuildContext context) {
    final tags = taskDetail?.tagsData ?? [];

    if (tags.isEmpty) {
      return GestureDetector(
        onTap: isTaskCompleted ? null : onTagTap,
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
      onTap: isTaskCompleted ? null : onTagTap,
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
    BuildContext context,
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
    BuildContext context,
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
      onTap: isUpdatingDates ? null : onTap,
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
                  color: isUpdatingDates
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isUpdatingDates)
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
    final assignTo = taskDetail?.assignTo;
    if (assignTo == null || assignTo.isEmpty) {
      return 'Not assigned';
    }

    // Parse assigned user IDs
    final assignedUserIds = assignTo
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((id) => id > 0)
        .toList();

    if (assignedUserIds.isEmpty) {
      return 'Not assigned';
    }

    // Find user names from site users
    List<SiteUserModel> assignedUsers = siteUsers
        .where((user) => assignedUserIds.contains(user.id))
        .toList();

    // If users are not loaded yet, show IDs as fallback
    if (siteUsers.isEmpty) {
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

    // If multiple users
    if (assignedUsers.isNotEmpty) {
      return '${assignedUsers.first.fullName} + ${assignedUsers.length - 1}';
    } else {
      return '${assignedUserIds.length} users assigned';
    }
  }
}
