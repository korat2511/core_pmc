import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../services/attendance_check_service.dart';
import '../services/site_service.dart';
import '../services/api_service.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/attendance_card.dart';
import '../widgets/custom_button.dart';
import '../screens/home_screen.dart';

class AttendanceCheckScreen extends StatefulWidget {
  const AttendanceCheckScreen({super.key});

  @override
  State<AttendanceCheckScreen> createState() => _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends State<AttendanceCheckScreen> {
  final AttendanceCheckService _attendanceService = AttendanceCheckService();
  final GlobalKey _attendanceCardKey = GlobalKey();
  
  bool _isLoading = false;
  bool _showPunchInForm = false;
  List<SiteModel> _availableSites = [];
  File? _capturedImage; // Image captured for attendance

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
    _loadSites();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAttendanceStatus() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _attendanceService.checkAttendance();
      if (success) {
        // Determine if we should show punch-in form
        setState(() {
          _showPunchInForm = _attendanceService.needsCheckIn;
        });
      } else {
        // Show error message if attendance check fails
        if (_attendanceService.errorMessage.isNotEmpty) {
          SnackBarUtils.showError(context, message: _attendanceService.errorMessage);
        }
      }
    } catch (e) {
      print('Error loading attendance status: $e');
      SnackBarUtils.showError(context, message: 'Failed to load attendance status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSites() async {
    try {
      final success = await SiteService.getSiteList(status: '');
      if (success) {
        setState(() {
          _availableSites = SiteService.sites;
        });
      }
    } catch (e) {
      print('Error loading sites: $e');
    }
  }

  Future<void> _handlePunchOut() async {
    // First, capture image
    final image = await _captureAttendanceImage('Check Out');
    if (image == null) {
      return; // User cancelled image capture
    }

    setState(() {
      _isLoading = true;
      _capturedImage = image;
    });

    try {
      // Get current location with better error handling
      Position currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        );
      } catch (locationError) {
        print('Location error during punch out: $locationError');
        // Use default coordinates if location fails
        currentPosition = Position(
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      // Get address from coordinates with timeout
      String address = 'Location not available';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPosition.latitude,
          currentPosition.longitude,
        ).timeout(Duration(seconds: 10));
        
        if (placemarks.isNotEmpty) {
          address = '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}'.trim();
          if (address.startsWith(',')) address = address.substring(1).trim();
          if (address.isEmpty) address = 'Location not available';
        }
      } catch (addressError) {
        print('Address error during punch out: $addressError');
        address = 'Location not available';
      }

      // Call saveAttendance API for punch out with image
      final success = await ApiService.saveAttendance(
        type: 'check_out',
        siteId: '', // Empty for punch out
        address: address,
        remark: '',
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
        image: _capturedImage!,
      );

      if (success) {
        SnackBarUtils.showSuccess(context, message: 'Successfully punched out');
        
        // Clear captured image
        setState(() {
          _capturedImage = null;
        });
        
        // Refresh attendance status and update UI
        await _loadAttendanceStatus();
        
        // Stay on the same screen - no navigation
      } else {
        SnackBarUtils.showError(context, message: 'Failed to punch out');
      }
    } catch (e) {
      print('Error during punch out: $e');
      SnackBarUtils.showError(context, message: 'Failed to punch out: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Future<void> _performAutoPunchIn() async {
    // First, capture image
    final image = await _captureAttendanceImage('Check In');
    if (image == null) {
      return; // User cancelled image capture
    }

    setState(() {
      _isLoading = true;
      _capturedImage = image;
    });

    try {
    // Load sites if not already loaded
    if (_availableSites.isEmpty) {
      await _loadSites();
    }

      // Get current location
      Position? currentPosition;
        try {
          currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
          );
        } catch (locationError) {
        print('Location error during auto punch-in: $locationError');
        // If location fails, allow check-in from somewhere else
        setState(() {
          _isLoading = false;
        });
        _showRemarkDialog();
        return;
      }

      // Find nearby sites within 500 meters
      SiteModel? nearbySite;
      double minDistance = double.infinity;

      for (SiteModel site in _availableSites) {
        if (site.latitude != null && site.longitude != null) {
          try {
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        site.latitude!,
        site.longitude!,
      );

            // Check if site is within 500 meters
            if (distanceInMeters <= 500 && distanceInMeters < minDistance) {
              minDistance = distanceInMeters;
              nearbySite = site;
            }
          } catch (e) {
            print('Error calculating distance for ${site.name}: $e');
          }
        }
      }

      setState(() {
        _isLoading = false;
      });

      // Perform punch-in with detected site or empty
      if (nearbySite != null) {
        // Site found within 500 meters - auto check-in (image already captured)
        _performPunchInWithLocation(nearbySite, currentPosition, _capturedImage);
      } else {
        // No site found within 500 meters - ask for remark
        _showRemarkDialog();
      }
    } catch (e) {
      print('Error during auto punch-in: $e');
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(context, message: 'Failed to detect nearby site: ${e.toString()}');
    }
  }

  // Removed site selection dialog - now using automatic site detection

  void _showRemarkDialog() {
    final remarkController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Check-in from Another Location',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a remark for checking in from a different location:',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: remarkController,
              decoration: InputDecoration(
                hintText: 'Enter your remark...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final remark = remarkController.text.trim();
              if (remark.isNotEmpty) {
                Navigator.of(context).pop();
                _performRemoteCheckIn(remark);
              } else {
                SnackBarUtils.showError(
                  context,
                  message: 'Please enter a remark',
                );
              }
            },
            child: Text('Check In'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRemoteCheckIn(String remark) async {
    // First, capture image
    final image = await _captureAttendanceImage('Check In');
    if (image == null) {
      return; // User cancelled image capture
    }

    setState(() {
      _isLoading = true;
      _capturedImage = image;
    });

    try {
      // Get current location with better error handling
      Position currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Reduced accuracy for faster response
          timeLimit: Duration(seconds: 15), // Increased timeout
        );
      } catch (locationError) {
        print('Location error: $locationError');
        // Use default coordinates if location fails
        currentPosition = Position(
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      // Get address from coordinates with timeout
      String address = 'Location not available';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPosition.latitude,
          currentPosition.longitude,
        ).timeout(Duration(seconds: 10));
        
        if (placemarks.isNotEmpty) {
          address = '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}'.trim();
          if (address.startsWith(',')) address = address.substring(1).trim();
          if (address.isEmpty) address = 'Location not available';
        }
      } catch (addressError) {
        print('Address error: $addressError');
        address = 'Location not available';
      }

      // Call saveAttendance API with null site_id for remote check-in
      final success = await ApiService.saveAttendance(
        type: 'check_in',
        siteId: '', // Empty string for remote check-in (null equivalent)
        address: address,
        remark: remark,
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
        image: _capturedImage!,
      );

      if (success) {
        SnackBarUtils.showSuccess(
          context, 
          message: 'Successfully checked in from remote location',
        );
        
        // Clear captured image
        setState(() {
          _capturedImage = null;
        });
        
        // Refresh attendance status and update UI
        await _loadAttendanceStatus();
        
        // Stay on the same screen - no navigation
      } else {
        SnackBarUtils.showError(context, message: 'Failed to check in from remote location');
      }
    } catch (e) {
      print('Error during remote check-in: $e');
      SnackBarUtils.showError(context, message: 'Failed to check in: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performPunchInWithLocation(SiteModel site, Position currentPosition, [File? preCapturedImage]) async {
    // Capture image if not already captured
    File? image = preCapturedImage;
    if (image == null) {
      image = await _captureAttendanceImage('Check In');
      if (image == null) {
        return; // User cancelled image capture
      }
    }

    setState(() {
      _isLoading = true;
      _capturedImage = image;
    });

    try {
      // Get address from coordinates with timeout
      String address = 'Location not available';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPosition.latitude,
          currentPosition.longitude,
        ).timeout(Duration(seconds: 10));
        
        if (placemarks.isNotEmpty) {
          address = '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}'.trim();
          if (address.startsWith(',')) address = address.substring(1).trim();
          if (address.isEmpty) address = 'Location not available';
        }
      } catch (addressError) {
        print('Address error: $addressError');
        address = 'Location not available';
      }

      // Call saveAttendance API
      final success = await ApiService.saveAttendance(
        type: 'check_in',
        siteId: site.id.toString(),
        address: address,
        remark: '',
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
        image: _capturedImage!,
      );

      if (success) {
        SnackBarUtils.showSuccess(
          context, 
          message: 'Successfully checked in at ${site.name}',
        );
        
        // Clear captured image
        setState(() {
          _capturedImage = null;
        });
        
        // Refresh attendance status and update UI
        await _loadAttendanceStatus();
        
        // Stay on the same screen - no navigation
      } else {
        SnackBarUtils.showError(context, message: 'Failed to check in');
      }
    } catch (e) {
      print('Error during check-in: $e');
      SnackBarUtils.showError(context, message: 'Failed to check in: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(
        title: 'Attendance',
        showBackButton: false,
        showDrawer: true,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(),
                ),
              );
            },
            tooltip: 'Home',
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Attendance Card with auto punch-in handler
                  AttendanceCard(
                    key: _attendanceCardKey,
                  onPunchInPressed: _performAutoPunchIn,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Punch Out Button (shown when user is checked in)
                  if (!_showPunchInForm) ...[
                    _buildPunchOutButton(),
                  ],
                ],
              ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
            ),
    );
  }



  Widget _buildPunchOutButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Punch Out',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: 12),
          
          Text(
            'You are currently checked in. Tap the button below to punch out.',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: 20),
          
          CustomButton(
            text: 'Punch Out',
            onPressed: _isLoading ? null : _handlePunchOut,
            isLoading: _isLoading,
            backgroundColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ],
      ),
    );
  }
}



