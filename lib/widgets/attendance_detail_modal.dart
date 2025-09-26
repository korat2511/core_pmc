import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/attendance_model.dart';
import '../models/site_model.dart';
import '../services/site_service.dart';

class AttendanceDetailModal extends StatefulWidget {
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
  State<AttendanceDetailModal> createState() => _AttendanceDetailModalState();
}

class _AttendanceDetailModalState extends State<AttendanceDetailModal> {
  GoogleMapController? _mapController;
  List<SiteModel> _allSites = [];
  bool _sitesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSitesIfNeeded();
  }

  Future<void> _loadSitesIfNeeded() async {
    // Only load sites if not already loaded
    if (SiteService.allSites.isEmpty && !_sitesLoaded) {
      setState(() {
        _sitesLoaded = true;
      });
      
      final success = await SiteService.getSiteList();
      if (success && mounted) {
        setState(() {
          _allSites = SiteService.allSites;
        });
      }
    } else if (SiteService.allSites.isNotEmpty) {
      setState(() {
        _allSites = SiteService.allSites;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPresent = widget.attendance?.isPresent ?? false;
    final isFutureDate = widget.date.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(context).colorScheme.primary,
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
                        '${widget.userName}\'s Attendance',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(widget.date),
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        ? Colors.green 
                        : (isFutureDate ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error),
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
                      color: Colors.white,
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
                  _buildDetailsSection(context, widget.attendance!),
                  
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),
                  
                  // Map Section
                  if (_hasLocationData(widget.attendance!))
                    _buildMapSection(context, widget.attendance!),
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
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.error,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  bool _hasLocationData(AttendanceModel attendance) {
    final hasCheckInLocation = attendance.latitudeIn != null && 
                               attendance.longitudeIn != null && 
                               attendance.latitudeIn!.isNotEmpty && 
                               attendance.longitudeIn!.isNotEmpty;
    
    final hasCheckOutLocation = attendance.latitudeOut != null && 
                               attendance.longitudeOut != null && 
                               attendance.latitudeOut!.isNotEmpty && 
                               attendance.longitudeOut!.isNotEmpty;
    
    return hasCheckInLocation || hasCheckOutLocation;
  }

  SiteModel? _getSiteById(int? siteId) {
    if (siteId == null) return null;
    try {
      return _allSites.firstWhere((site) => site.id == siteId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildMapSection(BuildContext context, AttendanceModel attendance) {
    final markers = <Marker>[];
    LatLng? centerLocation;
    
    // Add check-in marker
    if (attendance.latitudeIn != null && 
        attendance.longitudeIn != null && 
        attendance.latitudeIn!.isNotEmpty && 
        attendance.longitudeIn!.isNotEmpty) {
      final checkInLat = double.tryParse(attendance.latitudeIn!) ?? 0.0;
      final checkInLng = double.tryParse(attendance.longitudeIn!) ?? 0.0;
      final checkInLocation = LatLng(checkInLat, checkInLng);
      
      markers.add(
        Marker(
          markerId: const MarkerId('check_in'),
          position: checkInLocation,
          infoWindow: InfoWindow(
            title: 'Check-in Location',
            snippet: attendance.addressIn ?? 'Check-in address',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      
      centerLocation = checkInLocation;
    }
    
    // Add check-out marker
    if (attendance.latitudeOut != null && 
        attendance.longitudeOut != null && 
        attendance.latitudeOut!.isNotEmpty && 
        attendance.longitudeOut!.isNotEmpty) {
      final checkOutLat = double.tryParse(attendance.latitudeOut!) ?? 0.0;
      final checkOutLng = double.tryParse(attendance.longitudeOut!) ?? 0.0;
      final checkOutLocation = LatLng(checkOutLat, checkOutLng);
      
      markers.add(
        Marker(
          markerId: const MarkerId('check_out'),
          position: checkOutLocation,
          infoWindow: InfoWindow(
            title: 'Check-out Location',
            snippet: attendance.addressOut ?? 'Check-out address',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      
      if (centerLocation == null) {
        centerLocation = checkOutLocation;
      }
    }
    
    // Add site marker if site ID is available and site has location data
    final site = _getSiteById(attendance.siteId);
    if (site != null && site.latitude != null && site.longitude != null) {
      final siteLocation = LatLng(site.latitude!, site.longitude!);
      
      markers.add(
        Marker(
          markerId: MarkerId('site_${site.id}'),
          position: siteLocation,
          infoWindow: InfoWindow(
            title: 'Site: ${site.name}',
            snippet: site.address ?? 'Site location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      
      if (centerLocation == null) {
        centerLocation = siteLocation;
      }
    }
    
    // Calculate center location based on available markers
    if (markers.length > 1) {
      double totalLat = 0.0;
      double totalLng = 0.0;
      int validLocations = 0;
      
      for (final marker in markers) {
        totalLat += marker.position.latitude;
        totalLng += marker.position.longitude;
        validLocations++;
      }
      
      if (validLocations > 0) {
        centerLocation = LatLng(
          totalLat / validLocations,
          totalLng / validLocations,
        );
      }
    }
    
    // Default to India center if no location data
    centerLocation ??= const LatLng(20.5937, 78.9629);
    
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.responsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
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
                'Location History',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          
          // Map Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMapLegendItem(
                context,
                'Check-in',
                Colors.green,
                Icons.login,
              ),
              if (attendance.latitudeOut != null && 
                  attendance.longitudeOut != null && 
                  attendance.latitudeOut!.isNotEmpty && 
                  attendance.longitudeOut!.isNotEmpty)
                _buildMapLegendItem(
                  context,
                  'Check-out',
                  Colors.red,
                  Icons.logout,
                ),
              if (attendance.siteId != null && _getSiteById(attendance.siteId)?.latitude != null)
                _buildMapLegendItem(
                  context,
                  'Site',
                  Colors.blue,
                  Icons.location_city,
                ),
            ],
          ),
          
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          
          // Map
          Container(
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 200,
              tablet: 250,
              desktop: 300,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 12,
                  desktop: 16,
                ),
              ),
              border: Border.all(
                color: AppColors.borderColor,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 12,
                  desktop: 16,
                ),
              ),
              child: Stack(
                children: [
                  GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: centerLocation,
                  zoom: markers.length > 2 ? 10.0 : (markers.length > 1 ? 12.0 : 15.0),
                ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    markers: Set<Marker>.from(markers),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    mapType: MapType.normal,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                    },
                  ),
                  
                  // Map controls
                  _buildMapControls(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegendItem(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
            decoration: BoxDecoration(
            color: color,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveFontSize(
                  context,
                mobile: 8,
                tablet: 9,
                desktop: 10,
                ),
              ),
            ),
            child: Icon(
              icon,
            color: Colors.white,
              size: ResponsiveUtils.responsiveFontSize(
                context,
              mobile: 10,
              tablet: 12,
              desktop: 14,
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
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _focusOnCheckInLocation(AttendanceModel attendance) {
    if (attendance.latitudeIn != null && 
        attendance.longitudeIn != null && 
        attendance.latitudeIn!.isNotEmpty && 
        attendance.longitudeIn!.isNotEmpty) {
      final lat = double.tryParse(attendance.latitudeIn!) ?? 0.0;
      final lng = double.tryParse(attendance.longitudeIn!) ?? 0.0;
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          16.0,
        ),
      );
      
      SnackBarUtils.showSuccess(
        context,
        message: 'Focused on check-in location',
      );
    }
  }

  void _focusOnCheckOutLocation(AttendanceModel attendance) {
    if (attendance.latitudeOut != null && 
        attendance.longitudeOut != null && 
        attendance.latitudeOut!.isNotEmpty && 
        attendance.longitudeOut!.isNotEmpty) {
      final lat = double.tryParse(attendance.latitudeOut!) ?? 0.0;
      final lng = double.tryParse(attendance.longitudeOut!) ?? 0.0;
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          16.0,
        ),
      );
      
      SnackBarUtils.showSuccess(
        context,
        message: 'Focused on check-out location',
      );
    }
  }

  void _focusOnSiteLocation(AttendanceModel attendance) {
    final site = _getSiteById(attendance.siteId);
    if (site != null && site.latitude != null && site.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(site.latitude!, site.longitude!),
          16.0,
        ),
      );
      
      SnackBarUtils.showSuccess(
        context,
        message: 'Focused on site: ${site.name}',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: 'Site location not available',
      );
    }
  }

  Future<void> _showCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SnackBarUtils.showError(
            context,
            message: 'Location permission denied. Please enable location access in settings.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        SnackBarUtils.showError(
          context,
          message: 'Location permission permanently denied. Please enable location access in app settings.',
        );
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      // Animate camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15.0,
          ),
        );
      }

      SnackBarUtils.showSuccess(
        context,
        message: 'Showing current location',
      );
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Failed to get current location: $e',
      );
    }
  }

  Widget _buildMapControls(BuildContext context) {
    return Positioned(
      right: ResponsiveUtils.responsiveSpacing(
        context,
        mobile: 12,
        tablet: 16,
        desktop: 20,
      ),
      top: ResponsiveUtils.responsiveSpacing(
        context,
        mobile: 12,
        tablet: 16,
        desktop: 20,
      ),
      child: Column(
        children: [
          // Current Location Button
          Container(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 44,
              desktop: 48,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 44,
              desktop: 48,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
                onTap: _showCurrentLocation,
            child: Icon(
                  Icons.my_location,
                  color: Theme.of(context).colorScheme.primary,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
          ),
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
          
          // Zoom In Button
          Container(
            width: ResponsiveUtils.responsiveFontSize(
                      context,
              mobile: 40,
              tablet: 44,
              desktop: 48,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 44,
              desktop: 48,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveSpacing(
                      context,
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
                onTap: () {
                  _mapController?.animateCamera(
                    CameraUpdate.zoomIn(),
                  );
                },
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                ),
              ),
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
          
          // Zoom Out Button
          Container(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 44,
              desktop: 48,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 40,
              tablet: 44,
              desktop: 48,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveSpacing(
                      context,
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
                onTap: () {
                  _mapController?.animateCamera(
                    CameraUpdate.zoomOut(),
                  );
                },
                child: Icon(
                  Icons.remove,
                  color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, AttendanceModel attendance) {
    final hasCheckedOut = attendance.hasCheckedOut;
    final isAutoCheckout = attendance.isAutoCheckout;
    
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.responsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              color: Theme.of(context).colorScheme.onSurface,
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
            color: Colors.green,
            onTap: () => _focusOnCheckInLocation(attendance),
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
              color: Colors.blue,
              onTap: () => _focusOnCheckInLocation(attendance),
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
            color: isAutoCheckout ? Colors.orange : (hasCheckedOut ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () => _focusOnCheckOutLocation(attendance),
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
              color: Colors.blue,
              onTap: () => _focusOnCheckOutLocation(attendance),
            ),
          ],
          
          // Site Information
          if (attendance.siteId != null) ...[
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            _buildDetailRow(
              context,
              title: 'Site',
              value: _getSiteById(attendance.siteId)?.name ?? 'Site ID: ${attendance.siteId}',
              icon: Icons.location_city,
              color: Colors.blue,
              onTap: () => _focusOnSiteLocation(attendance),
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
    VoidCallback? onTap,
  }) {
    Widget content = Row(
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(context).colorScheme.onSurface,
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    
    return content;
  }
}
