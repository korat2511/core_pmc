import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';

class CustomCalendar extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onMonthChanged;
  final Color Function(DateTime) getDayColor;
  final bool isLoading;

  const CustomCalendar({
    super.key,
    required this.selectedMonth,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.getDayColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildWeekHeader(),
          const SizedBox(height: 8),
          _buildCalendarGrid(daysInMonth, firstWeekday),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: SizedBox(
            height: 24,
            child: Center(
              child: Text(
                day,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstWeekday) {
    final List<Widget> calendarDays = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      calendarDays.add(const Expanded(child: SizedBox(height: 24)));
    }
    
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);
      final isSelected = selectedDay != null && 
          selectedDay!.year == date.year && 
          selectedDay!.month == date.month && 
          selectedDay!.day == date.day;
      final isToday = DateTime.now().year == date.year && 
          DateTime.now().month == date.month && 
          DateTime.now().day == date.day;
      
      calendarDays.add(
        Expanded(
          child: Container(
            height: 30,

            margin: const EdgeInsets.all(2),
            child: GestureDetector(
              onTap: () => onDaySelected(date, date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryColor 
                      : (isToday ? AppColors.primaryColor.withOpacity(0.8) : getDayColor(date)),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primaryColor 
                        : AppColors.borderColor,
                    width: isSelected ? 1 : 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,

                      color: (isSelected || isToday || getDayColor(date) != AppColors.textSecondary.withOpacity(0.2)) 
                          ? AppColors.textWhite 
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Fill remaining cells to complete the grid
    final totalCells = 42; // 6 rows * 7 days
    final remainingCells = totalCells - calendarDays.length;
    for (int i = 0; i < remainingCells; i++) {
      calendarDays.add(const Expanded(child: SizedBox(height: 24)));
    }
    
    // Create rows of 7 days each
    final List<Widget> rows = [];
    for (int i = 0; i < calendarDays.length; i += 7) {
      final rowDays = calendarDays.sublist(i, (i + 7 < calendarDays.length) ? i + 7 : calendarDays.length);
      rows.add(
        Row(
          children: rowDays,
        ),
      );
    }
    
    return Column(
      children: rows,
    );
  }
}
