import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../screens/grn_detail_screen.dart';

class GrnListItem extends StatelessWidget {
  final String grnNumber;
  final String grnDate;
  final String vendorName;
  final String remarks;
  final int grnId;
  final VoidCallback? onTap;

  const GrnListItem({
    super.key,
    required this.grnNumber,
    required this.grnDate,
    required this.vendorName,
    required this.remarks,
    required this.grnId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          grnNumber,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $grnDate'),
            Text('Vendor: $vendorName'),
            if (remarks.isNotEmpty) Text('Remarks: $remarks'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap ?? () {
          // Navigate to GRN detail screen
          NavigationUtils.push(
            context,
            GrnDetailScreen(grnId: grnId),
          );
        },
      ),
    );
  }
}
