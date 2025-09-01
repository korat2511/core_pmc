import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/task_detail_model.dart';
import '../models/unit_model.dart';

class TaskUnitSection extends StatelessWidget {
  final TaskDetailModel? taskDetail;
  final UnitModel? selectedUnit;
  final bool isLoadingUnits;
  final bool hasProgress;
  final bool isTaskCompleted;
  final VoidCallback? onUnitTap;
  final VoidCallback? onTaskCompletedWarning;

  const TaskUnitSection({
    super.key,
    required this.taskDetail,
    required this.selectedUnit,
    required this.isLoadingUnits,
    required this.hasProgress,
    required this.isTaskCompleted,
    this.onUnitTap,
    this.onTaskCompletedWarning,
  });

  @override
  Widget build(BuildContext context) {
    final totalWork = taskDetail?.totalWork ?? 0;
    final totalWorkDone = taskDetail?.totalWorkDone ?? 0;
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
                          '$totalWork ${selectedUnit?.symbol ?? taskDetail?.unit ?? '%'}',
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
                          '$totalWorkDone ${selectedUnit?.symbol ?? taskDetail?.unit ?? '%'}',
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
                          '$workLeft ${selectedUnit?.symbol ?? taskDetail?.unit ?? '%'}',
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
            onTap: isLoadingUnits || hasProgress ? null : (isTaskCompleted ? onTaskCompletedWarning : onUnitTap),
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
                    selectedUnit?.symbol ?? taskDetail?.unit ?? '%',
                    style: AppTypography.bodyMedium.copyWith(
                      color: (hasProgress || isTaskCompleted)
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Spacer(),
                  if (isLoadingUnits)
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
}
