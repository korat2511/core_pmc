import '../models/attendance_model.dart';
import '../models/attendance_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';

class AttendanceService {
  List<AttendanceModel> _attendanceData = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<AttendanceModel> get attendanceData => _attendanceData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Get attendance report from API
  Future<bool> getAttendanceReport({
    required int userId,
    required String startDate,
    required String endDate,
    int page = 1,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';

      // Get API token from local storage
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isLoading = false;
        return false;
      }

      // Call API
      final AttendanceResponse response = await ApiService.getAttendanceReport(
        apiToken: apiToken,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        page: page,
      );

      if (response.isSuccess) {
        _attendanceData = response.data;
        _isLoading = false;
        return true;
      } else {
        _errorMessage = 'Failed to load attendance data';
        _isLoading = false;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load attendance: $e';
      _isLoading = false;
      return false;
    }
  }

  // Get attendance for a specific date
  AttendanceModel? getAttendanceForDate(String date) {
    try {
      return _attendanceData.firstWhere((attendance) => attendance.date == date);
    } catch (e) {
      return null;
    }
  }

  // Check if user was present on a specific date
  bool isPresentOnDate(String date) {
    final attendance = getAttendanceForDate(date);
    return attendance?.isPresent ?? false;
  }

  // Check if user was absent on a specific date
  bool isAbsentOnDate(String date) {
    final attendance = getAttendanceForDate(date);
    return attendance?.isAbsent ?? true;
  }

  // Get attendance status for a date (present, absent, or future)
  String getAttendanceStatus(String date) {
    try {
      final attendance = getAttendanceForDate(date);
      if (attendance == null) {
        // Check if date is in the future
        final dateTime = DateTime.parse(date);
        final now = DateTime.now();
        if (dateTime.isAfter(DateTime(now.year, now.month, now.day))) {
          return 'future';
        }
        return 'absent';
      }
      return attendance.isPresent ? 'present' : 'absent';
    } catch (e) {
      // If there's any error parsing the date, treat it as absent
      return 'absent';
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
  }

  // Clear attendance data
  void clearAttendanceData() {
    _attendanceData.clear();
  }
}
