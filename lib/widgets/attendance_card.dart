import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../services/attendance_check_service.dart';
import '../services/api_service.dart';

class AttendanceCard extends StatefulWidget {
  final VoidCallback? onPunchInPressed;
  final VoidCallback? onRefresh;
  
  const AttendanceCard({
    super.key,
    this.onPunchInPressed,
    this.onRefresh,
  });

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  final AttendanceCheckService _attendanceService = AttendanceCheckService();
  
  bool _isPunchedIn = false;
  DateTime? _punchInTime;
  DateTime? _punchOutTime;
  bool _isLoading = false;
  
  // Address related variables
  String _currentAddress = '';
  bool _isLoadingAddress = false;
  bool _hasAddressError = false;
  String _addressError = '';

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
  }

  @override
  void didUpdateWidget(AttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload attendance status when widget updates
    _loadAttendanceStatus();
  }

  // Public method to refresh attendance data
  Future<void> refreshAttendance() async {
    await _loadAttendanceStatus();
  }

  Future<void> _loadAttendanceStatus() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _attendanceService.checkAttendance();
      
      if (success && _attendanceService.attendanceData != null) {
        final data = _attendanceService.attendanceData!;
        

        
        // Determine if user is punched in based on flag
        if (data.flag == 'check_out') {
          // User is checked in, needs to check out
          _isPunchedIn = true;
          if (data.data != null) {
            _punchInTime = _parseTime(data.data!.inTime);
            _punchOutTime = null; // No checkout time yet
          }
        } else {
          // User needs to check in (flag == 'check_in')
          _isPunchedIn = false;
          _punchInTime = null;
          
          // Show last attendance data
          if (data.lastAttendance != null) {
            _punchInTime = _parseTime(data.lastAttendance!.inTime);
            _punchOutTime = _parseTime(data.lastAttendance!.outTime ?? '');
          }
        }
      } else {
        // Default state if API fails
        _isPunchedIn = false;
        _punchInTime = null;
        _punchOutTime = null;
      }
    } catch (e) {
      print('Error loading attendance status: $e');
      // Handle error
      _isPunchedIn = false;
      _punchInTime = null;
      _punchOutTime = null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    // Load current address only if still mounted
    if (mounted) {
      _getCurrentAddress();
    }
  }

  DateTime? _parseTime(String timeString) {
    if (timeString.isEmpty || timeString == 'null') return null;
    
    try {
      final now = DateTime.now();
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        // Handle auto checkout at midnight (00:00:00)
        if (hour == 0 && minute == 0) {
          print('Auto checkout detected at midnight from $timeString');
          return DateTime(now.year, now.month, now.day, 0, 0); // 12:00 AM
        }
        
        print('Parsed time: $hour:$minute from $timeString');
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      print('Error parsing time: $e for string: $timeString');
    }
    return null;
  }

  Future<void> _handlePunchIn() async {
    if (widget.onPunchInPressed != null) {
      widget.onPunchInPressed!();
    }
  }

  Future<void> _handlePunchOut() async {
    if (!mounted) return;
    
    // First, capture image
    final image = await _captureAttendanceImage('Check Out');
    if (image == null) {
      return; // User cancelled image capture
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      
      String address = placemarks.isNotEmpty 
          ? '${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.administrativeArea}'
          : 'Location not available';

      // Call saveAttendance API for check-out with image
      final success = await ApiService.saveAttendance(
        type: 'check_out',
        siteId: '', // Empty for check-out (no site validation needed)
        address: address,
        remark: '',
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
        image: image,
      );

      if (success && mounted) {
        setState(() {
          _isPunchedIn = false;
          _punchOutTime = DateTime.now();
          _isLoading = false;
        });

        // Show success message
        SnackBarUtils.showSuccess(
          context,
          message: 'Successfully checked out',
        );
        
        // Refresh attendance status
        await _loadAttendanceStatus();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        SnackBarUtils.showError(
          context,
          message: 'Failed to check out. Please try again.',
        );
      }
    } catch (e) {
      print('Error during check-out: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        SnackBarUtils.showError(
          context,
          message: 'Failed to check out: ${e.toString()}',
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    // Handle midnight (auto checkout)
    if (time.hour == 0 && time.minute == 0) {
      return '12:00 AM';
    }
    
    // Format time in 12-hour format
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    
    return '$hour:$minute $period';
  }


  Future<File?> _captureAttendanceImage(String action) async {
    // Use existing showImageSourceDialog from ImagePickerUtils
    final file = await ImagePickerUtils.showImageSourceDialog(
      context: context,
      chooseMultiple: false,
      imageQuality: 50, // Lower quality for smaller file size
    );
    
    if (file == null) {
      return null; // User cancelled
    }
    
    // Compress to 512 KB max
    final compressedFile = await ImagePickerUtils.compressImageToSize(
      file,
      maxSizeInKB: 512.0,
    );
    
    if (compressedFile == null) {
      return null;
    }
    
    // Validate final size
    final finalSizeKB = ImagePickerUtils.getImageSizeInMB(compressedFile) * 1024;
    if (finalSizeKB > 512.0 && mounted) {
      SnackBarUtils.showError(
        context,
        message: 'Image is too large (${finalSizeKB.toStringAsFixed(0)} KB). Please try again with a smaller image.',
      );
      return null;
    }
    
    return compressedFile;
  }

  String _getErrorMessage(String error) {
    if (error.contains('Location services are disabled')) {
      return 'Location services are disabled. Please enable GPS in your device settings.';
    } else if (error.contains('Location permission denied')) {
      return 'Location permission denied. Please allow location access in app settings.';
    } else if (error.contains('permanently denied')) {
      return 'Location access permanently denied. Please enable it in device settings.';
    } else if (error.contains('timeout') || error.contains('TimeoutException')) {
      return 'Location request timed out. Please check your GPS signal and try again.';
    } else if (error.contains('network') || error.contains('NetworkException')) {
      return 'Network error while getting location. Please check your internet connection.';
    } else if (error.contains('Could not get address from coordinates')) {
      return 'Unable to get address from location. Please try again.';
    } else {
      return 'Unable to get your location. Please try again.';
    }
  }

  Future<void> _getCurrentAddress() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingAddress = true;
      _hasAddressError = false;
      _addressError = '';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += address.isNotEmpty ? ', ${place.subLocality}' : place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += address.isNotEmpty ? ', ${place.locality}' : place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          address += address.isNotEmpty ? ', ${place.administrativeArea}' : place.administrativeArea!;
        }

        if (mounted) {
          setState(() {
            _currentAddress = address.isNotEmpty ? address : 'Address not available';
            _isLoadingAddress = false;
          });
        }
      } else {
        throw Exception('Could not get address from coordinates');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasAddressError = true;
          _addressError = e.toString();
          _currentAddress = 'Unable to get location';
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.05),
            AppColors.surfaceColor,
            AppColors.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 20,
            tablet: 24,
            desktop: 28,
          ),
        ),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          children: [


            Column(
              children: [
                // Time display with modern design
                Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: AppColors.textWhite,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModernTimeCard(
                          context,
                          title: 'CHECK IN',
                          time: _punchInTime != null ? _formatTime(_punchInTime!) : '--:--',
                          icon: Icons.login_rounded,
                          color: AppColors.successColor,
                          isActive: _isPunchedIn,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 60,
                          tablet: 70,
                          desktop: 80,
                        ),
                        color: AppColors.borderColor.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildModernTimeCard(
                          context,
                          title: 'CHECK OUT',
                          time: _punchOutTime != null ? _formatTime(_punchOutTime!) : '--:--',
                          icon: Icons.logout_rounded,
                          color: AppColors.errorColor,
                          isActive: !_isPunchedIn && _punchInTime != null,
                        ),
                      ),
                    ],
                                     ),
                 ),
               ],
             ),

            Padding(
              padding:  ResponsiveUtils.verticalPadding(context),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: _hasAddressError ? AppColors.errorColor : AppColors.infoColor,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
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
                    child: _isLoadingAddress
                        ? Row(
                            children: [
                              SizedBox(
                                width: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                height: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                child: CircularProgressIndicator(
                                  color: AppColors.infoColor,
                                  strokeWidth: 2,
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
                              Text(
                                'Getting your location...',
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
                          )
                        : _hasAddressError
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getErrorMessage(_addressError),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: ResponsiveUtils.responsiveFontSize(
                                        context,
                                        mobile: 14,
                                        tablet: 16,
                                        desktop: 18,
                                      ),
                                      color: AppColors.errorColor,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: _getCurrentAddress,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          color: AppColors.errorColor,
                                          size: ResponsiveUtils.responsiveFontSize(
                                            context,
                                            mobile: 14,
                                            tablet: 16,
                                            desktop: 18,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Retry',
                                          style: AppTypography.bodySmall.copyWith(
                                            fontSize: ResponsiveUtils.responsiveFontSize(
                                              context,
                                              mobile: 11,
                                              tablet: 13,
                                              desktop: 15,
                                            ),
                                            color: AppColors.errorColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _currentAddress.isNotEmpty ? _currentAddress : 'Location not available',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _isPunchedIn ? null : _handlePunchIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                    child: _isLoading && !_isPunchedIn
                        ? SizedBox(
                            height: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            width: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            child: CircularProgressIndicator(
                              color: AppColors.textWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.login,
                                size: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
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
                              Text(
                                'Punch In',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                  child: ElevatedButton(
                    onPressed: _isLoading || !_isPunchedIn ? null : _handlePunchOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorColor,
                      foregroundColor: AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                    child: _isLoading && _isPunchedIn
                        ? SizedBox(
                            height: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            width: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            child: CircularProgressIndicator(
                              color: AppColors.textWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                size: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
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
                              Text(
                                'Punch Out',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTimeCard(
    BuildContext context, {
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        children: [
          Container(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 50,
              tablet: 55,
              desktop: 60,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 50,
              tablet: 55,
              desktop: 60,
            ),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.2) : AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 25,
                  tablet: 27,
                  desktop: 30,
                ),
              ),
              border: Border.all(
                color: isActive ? color : AppColors.borderColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? color : AppColors.textSecondary,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 24,
                tablet: 26,
                desktop: 28,
              ),
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
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 10,
                tablet: 12,
                desktop: 14,
              ),
              color: isActive ? color : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          Text(
            time,
            style: AppTypography.titleLarge.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              color: isActive ? color : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

} 