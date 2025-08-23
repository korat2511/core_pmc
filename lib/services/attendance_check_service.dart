import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/attendance_check_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AttendanceCheckService {
  AttendanceCheckModel? _attendanceData;
  String _errorMessage = '';
  bool _isLoading = false;

  AttendanceCheckModel? get attendanceData => _attendanceData;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> checkAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = AuthService.currentToken;
      if (token == null) {
        _errorMessage = 'Authentication token not found';
        return false;
      }

      final response = await ApiService.attendanceCheck(apiToken: token);

      log("Attendance Check - ${response?.lastAttendance!.date}");

      
      if (response != null) {
        _attendanceData = response;
        return true;
      } else {
        _errorMessage = 'Failed to check attendance';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error checking attendance: $e';
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void setState(VoidCallback fn) {
    fn();
  }

  void clearData() {
    _attendanceData = null;
    _errorMessage = '';
    _isLoading = false;
  }

  bool get needsCheckIn => _attendanceData?.flag == 'check_in';
  bool get needsCheckOut => _attendanceData?.flag == 'check_out';
  AttendanceDataModel? get currentAttendance => _attendanceData?.data;
  AttendanceDataModel? get lastAttendance => _attendanceData?.lastAttendance;
}
