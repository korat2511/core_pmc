import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';

class AttendanceCard extends StatefulWidget {
  const AttendanceCard({super.key});

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
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

  void _loadAttendanceStatus() {
    // TODO: Load attendance status from API/local storage
    // For now, using mock data
    setState(() {
      _isPunchedIn = false;
      _punchInTime = null;
      _punchOutTime = null;
    });
    
    // Load current address
    _getCurrentAddress();
  }

  Future<void> _handlePunchIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Call API to punch in
      await Future.delayed(Duration(milliseconds: 1000)); // Simulate API call
      
      setState(() {
        _isPunchedIn = true;
        _punchInTime = DateTime.now();
        _punchOutTime = null;
        _isLoading = false;
      });

      // Show success message
      SnackBarUtils.showSuccess(
        context,
        message: 'Successfully punched in at ${_formatTime(_punchInTime!)}',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      SnackBarUtils.showError(
        context,
        message: 'Failed to punch in. Please try again.',
      );
    }
  }

  Future<void> _handlePunchOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Call API to punch out
      await Future.delayed(Duration(milliseconds: 1000)); // Simulate API call
      
      setState(() {
        _isPunchedIn = false;
        _punchOutTime = DateTime.now();
        _isLoading = false;
      });

      // Show success message
      SnackBarUtils.showSuccess(
        context,
        message: 'Successfully punched out at ${_formatTime(_punchOutTime!)}',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      SnackBarUtils.showError(
        context,
        message: 'Failed to punch out. Please try again.',
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _getCurrentDate() {
    return _formatDate(DateTime.now());
  }

  Future<void> _getCurrentAddress() async {
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

        setState(() {
          _currentAddress = address.isNotEmpty ? address : 'Address not available';
          _isLoadingAddress = false;
        });
      } else {
        throw Exception('Could not get address from coordinates');
      }
    } catch (e) {
      setState(() {
        _hasAddressError = true;
        _addressError = e.toString();
        _currentAddress = 'Unable to get location';
        _isLoadingAddress = false;
      });
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
              padding:  EdgeInsets.symmetric(
                vertical: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 24,
                )
              ),
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
                  if (_hasAddressError || _isLoadingAddress)
                    IconButton(
                      onPressed: _isLoadingAddress ? null : _getCurrentAddress,
                      icon: _isLoadingAddress
                          ? SizedBox(
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
                          color: AppColors.errorColor,
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(
                        Icons.refresh,
                        color: AppColors.errorColor,
                        size: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                  if (_isLoadingAddress)
                    Row(
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
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _currentAddress.isNotEmpty ? _currentAddress : 'Location not available',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: _hasAddressError ? AppColors.errorColor : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  if (_hasAddressError && _addressError.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 4,
                          tablet: 6,
                          desktop: 8,
                        ),
                      ),
                      child: Text(
                        'Error: ${_addressError}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 10,
                            tablet: 12,
                            desktop: 14,
                          ),
                          color: AppColors.errorColor,
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

  Widget _buildTimeCard(
    BuildContext context, {
    required String title,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 22,
              desktop: 24,
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
              mobile: 4,
              tablet: 6,
              desktop: 8,
            ),
          ),
          Text(
            time,
            style: AppTypography.titleMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 