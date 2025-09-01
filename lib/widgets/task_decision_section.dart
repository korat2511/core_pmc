import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/task_detail_model.dart';

class TaskDecisionSection extends StatelessWidget {
  final TaskDetailModel? taskDetail;
  final bool isTaskCompleted;
  final bool canChangeDecision;
  final VoidCallback? onDecisionTap;
  final VoidCallback? onTaskCompletedWarning;

  const TaskDecisionSection({
    super.key,
    required this.taskDetail,
    required this.isTaskCompleted,
    required this.canChangeDecision,
    this.onDecisionTap,
    this.onTaskCompletedWarning,
  });

  @override
  Widget build(BuildContext context) {
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
            onTap: (isTaskCompleted || !canChangeDecision)
                ? (isTaskCompleted ? onTaskCompletedWarning : null)
                : onDecisionTap,
            child: Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                SizedBox(width: 8),
                Text(
                  '${taskDetail?.categoryName ?? 'Category'} Pending From',
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
                            color: (isTaskCompleted || !canChangeDecision)
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!isTaskCompleted && canChangeDecision)
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
                '${taskDetail?.categoryName ?? 'Category'} Due From',
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
                  taskDetail?.completionDate ?? 'N/A',
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

  String _buildDecisionPendingFromText() {
    final decisionByAgency = taskDetail?.decisionByAgency;
    if (decisionByAgency == null || decisionByAgency.isEmpty) {
      return 'N/A';
    }

    // If decision_by_agency is "Other", show decision_pending_other
    if (decisionByAgency.toLowerCase() == 'other') {
      return taskDetail?.decisionPendingOther ?? 'N/A';
    }

    // Otherwise show the agency name
    return decisionByAgency;
  }
}
