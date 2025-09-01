import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/task_detail_model.dart';
import '../models/task_detail_model.dart';

class TaskProgressCard extends StatelessWidget {
  final ProgressDetailModel progress;
  final TaskDetailModel? taskDetail;

  const TaskProgressCard({
    super.key,
    required this.progress,
    this.taskDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            Icon(Icons.bar_chart, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              'Progress update - ${progress.workDone ?? '0'}${taskDetail?.unit ?? '%'}',
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
          _buildUsedMaterialsSection(context, progress.usedMaterial),
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

  Widget _buildUsedMaterialsSection(BuildContext context, List<UsedMaterialModel> usedMaterials) {
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
}
