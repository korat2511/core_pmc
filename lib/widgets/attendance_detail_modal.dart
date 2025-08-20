import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../models/attendance_model.dart';

class AttendanceDetailModal extends StatelessWidget {
  final DateTime date;
  final AttendanceModel? attendance;
  final String userName;

  const AttendanceDetailModal({
    super.key,
    required this.date,
    this.attendance,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = attendance?.isPresent ?? false;
    final hasCheckedOut = attendance?.hasCheckedOut ?? false;
    final isFutureDate = date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    final isAbsent = !isPresent && !isFutureDate;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
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
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primaryColor,
                  size: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 16,
                    desktop: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$userName\'s Attendance',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(date),
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                    vertical: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 4,
                      tablet: 6,
                      desktop: 8,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: isPresent 
                        ? AppColors.successColor 
                        : (isFutureDate ? AppColors.textSecondary : AppColors.errorColor),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
                    ),
                  ),
                  child: Text(
                    isPresent 
                        ? 'Present' 
                        : (isFutureDate ? 'Not Available' : 'Absent'),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          if (isPresent) ...[
            Container(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                children: [
                  // Details Section
                  _buildDetailsSection(context, attendance!),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                children: [
                  Icon(
                    isFutureDate 
                        ? Icons.event_busy_outlined
                        : Icons.event_busy_outlined,
                    color: isFutureDate 
                        ? AppColors.textSecondary
                        : AppColors.errorColor,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 48,
                      tablet: 56,
                      desktop: 64,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),
                  Text(
                    isFutureDate 
                        ? 'Date not available yet'
                        : 'No attendance record for this date',
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          
          // Bottom padding
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.responsivePadding(context),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 45,
              desktop: 50,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 45,
              desktop: 50,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 25,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
          ),
          SizedBox(
            width: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 2,
                    tablet: 4,
                    desktop: 6,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Widget _buildDetailsSection(BuildContext context, AttendanceModel attendance) {
    final hasCheckedOut = attendance.hasCheckedOut;
    final isAutoCheckout = attendance.isAutoCheckout;
    
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.responsivePadding(context),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: AppTypography.titleMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          
          // Check-in Section
          _buildDetailRow(
            context,
            title: 'In Time',
            value: attendance.checkInTime,
            icon: Icons.login_outlined,
            color: AppColors.successColor,
          ),
          
          if (attendance.addressIn != null && attendance.addressIn!.isNotEmpty) ...[
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ),
            ),
            _buildDetailRow(
              context,
              title: 'In Address',
              value: attendance.addressIn!,
              icon: Icons.location_on_outlined,
              color: AppColors.infoColor,
            ),
          ],
          
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          
          // Check-out Section
          _buildDetailRow(
            context,
            title: 'Out Time',
            value: attendance.checkoutStatusText,
            icon: Icons.logout_outlined,
            color: isAutoCheckout ? AppColors.warningColor : (hasCheckedOut ? AppColors.errorColor : AppColors.textSecondary),
          ),
          
          if (attendance.addressOut != null && attendance.addressOut!.isNotEmpty) ...[
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ),
            ),
            _buildDetailRow(
              context,
              title: 'Out Address',
              value: attendance.addressOut!,
              icon: Icons.location_on_outlined,
              color: AppColors.infoColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 32,
            tablet: 36,
            desktop: 40,
          ),
          height: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 32,
            tablet: 36,
            desktop: 40,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
          ),
        ),
        SizedBox(
          width: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 8,
            tablet: 12,
            desktop: 16,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 14,
                  ),
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 2,
                  tablet: 4,
                  desktop: 6,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
