import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerUtils {
  static const String _defaultFormat = 'dd-MM-yyyy';
  static const String _apiFormat = 'dd-MM-yyyy';

  /// Show date picker and return selected date as formatted string
  static Future<String?> pickDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String format = _defaultFormat,
    String? title,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      return DateFormat(format).format(picked);
    }
    return null;
  }

  /// Format date string from one format to another
  static String formatDate(String dateString, {String fromFormat = _apiFormat, String toFormat = _defaultFormat}) {
    try {
      final DateTime date = DateFormat(fromFormat).parse(dateString);
      return DateFormat(toFormat).format(date);
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  /// Parse date string to DateTime object
  static DateTime? parseDate(String dateString, {String format = _apiFormat}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get current date as formatted string
  static String getCurrentDate({String format = _defaultFormat}) {
    return DateFormat(format).format(DateTime.now());
  }

  /// Get date for API (dd-MM-yyyy format)
  static String getDateForAPI(DateTime date) {
    return DateFormat(_apiFormat).format(date);
  }

  /// Get date for display (dd-MM-yyyy format)
  static String getDateForDisplay(DateTime date) {
    return DateFormat(_defaultFormat).format(date);
  }

  /// Check if date string is valid
  static bool isValidDate(String dateString, {String format = _apiFormat}) {
    try {
      DateFormat(format).parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get relative date string (e.g., "2 days ago", "next week")
  static String getRelativeDate(String dateString, {String format = _apiFormat}) {
    try {
      final DateTime date = DateFormat(format).parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = date.difference(now);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Tomorrow';
      } else if (difference.inDays == -1) {
        return 'Yesterday';
      } else if (difference.inDays > 0) {
        return 'In ${difference.inDays} days';
      } else {
        return '${difference.inDays.abs()} days ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  /// Get month name from date
  static String getMonthName(String dateString, {String format = _apiFormat}) {
    try {
      final DateTime date = DateFormat(format).parse(dateString);
      return DateFormat('MMMM').format(date);
    } catch (e) {
      return '';
    }
  }

  /// Get year from date
  static int? getYear(String dateString, {String format = _apiFormat}) {
    try {
      final DateTime date = DateFormat(format).parse(dateString);
      return date.year;
    } catch (e) {
      return null;
    }
  }

  /// Check if date is in the past
  static bool isPastDate(String dateString, {String format = _apiFormat}) {
    try {
      final DateTime date = DateFormat(format).parse(dateString);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Check if date is in the future
  static bool isFutureDate(String dateString, {String format = _apiFormat}) {
    try {
      final DateTime date = DateFormat(format).parse(dateString);
      return date.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Get days between two dates
  static int getDaysBetween(String startDate, String endDate, {String format = _apiFormat}) {
    try {
      final DateTime start = DateFormat(format).parse(startDate);
      final DateTime end = DateFormat(format).parse(endDate);
      return end.difference(start).inDays;
    } catch (e) {
      return 0;
    }
  }
}
