import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/attendance_service.dart';
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/attendance_detail_modal.dart';
import '../widgets/custom_calendar.dart';

class AttendanceScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const AttendanceScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  DateTime _selectedMonth = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    
    // Add a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _attendanceService.isLoading) {
        print('Loading timeout reached, forcing state update');
        setState(() {
          // Force rebuild
        });
      }
    });
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      // Ensure loading state is set
    });
    
    final startDate = _getMonthStartDate();
    final endDate = _getMonthEndDate();



    final success = await _attendanceService.getAttendanceReport(
      userId: widget.userId,
      startDate: startDate,
      endDate: endDate,
    );

    print('Attendance load result: $success');
    print('Attendance data count: ${_attendanceService.attendanceData.length}');
    print('Error message: ${_attendanceService.errorMessage}');

    if (mounted) {
      setState(() {
        // Force rebuild to update loading state
      });
      
      if (!success) {
        // Check for session expiration
        if (_attendanceService.errorMessage.contains('Session expired')) {
          await SessionManager.handleSessionExpired(context);
        } else {
          SnackBarUtils.showError(
            context,
            message: _attendanceService.errorMessage,
          );
        }
      }
    }
  }

  String _getMonthStartDate() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    return '${firstDay.day.toString().padLeft(2, '0')}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.year}';
  }

  String _getMonthEndDate() {
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return '${lastDay.day.toString().padLeft(2, '0')}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.year}';
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _selectedMonth = month;
      _focusedDay = month;
    });
    _loadAttendanceData();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Show attendance details in modal bottom sheet
    final dateString = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
    final attendance = _attendanceService.getAttendanceForDate(dateString);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendanceDetailModal(
        date: selectedDay,
        attendance: attendance,
        userName: widget.userName,
      ),
    );
  }

  Color _getDayColor(DateTime day) {
    try {
      final dateString = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final status = _attendanceService.getAttendanceStatus(dateString);
      
      switch (status) {
        case 'present':
          return Colors.green.withOpacity(0.65); // Light green
        case 'absent':
          return Theme.of(context).colorScheme.error.withOpacity(0.65); // Light red
        case 'future':
          return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2); // Light grey
        default:
          return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2);
      }
    } catch (e) {
      return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.userName}\'s Attendance',
        showDrawer: false,
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    final previousMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                    _onMonthChanged(previousMonth);
                  },
                  icon: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).colorScheme.primary,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),
                ),
                Text(
                  '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    // Don't allow future months
                    if (nextMonth.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                      _onMonthChanged(nextMonth);
                    }
                  },
                  icon: Icon(
                    Icons.chevron_right,
                    color: _selectedMonth.isBefore(DateTime.now().add(const Duration(days: 1))) 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Legend
          Container(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Present', Colors.green.withOpacity(0.65)),
                _buildLegendItem('Absent', Theme.of(context).colorScheme.error.withOpacity(0.65)),
                _buildLegendItem('Future', Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2)),
              ],
            ),
          ),
          // Calendar
          Expanded(
            child: _attendanceService.isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                      SizedBox(height: 16),
                      Text(
                        'Loading attendance data...',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            // Force reload
                          });
                          _loadAttendanceData();
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  )
                : CustomCalendar(
                    selectedMonth: _selectedMonth,
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    onDaySelected: _onDaySelected,
                    onMonthChanged: _onMonthChanged,
                    getDayColor: _getDayColor,
                    isLoading: _attendanceService.isLoading,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
          height: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 6,
                tablet: 7,
                desktop: 8,
              ),
            ),
          ),
        ),
        SizedBox(
          width: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 4,
            tablet: 6,
            desktop: 8,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 10,
              tablet: 12,
              desktop: 14,
            ),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }



  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}


