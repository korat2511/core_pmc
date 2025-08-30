import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../services/attendance_check_service.dart';
import '../services/site_service.dart';
import '../services/api_service.dart';
import '../models/site_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/attendance_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../screens/home_screen.dart';

class AttendanceCheckScreen extends StatefulWidget {
  const AttendanceCheckScreen({super.key});

  @override
  State<AttendanceCheckScreen> createState() => _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends State<AttendanceCheckScreen> {
  final AttendanceCheckService _attendanceService = AttendanceCheckService();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _attendanceCardKey = GlobalKey();
  
  bool _isLoading = false;
  bool _showPunchInForm = false;
  SiteModel? _selectedSite;
  List<SiteModel> _availableSites = [];
  List<SiteModel> _filteredSites = [];
  
  // Cache for site location status to prevent repeated API calls
  final Map<int, String> _siteLocationCache = {};
  Position? _cachedPosition;

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
    _loadSites();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
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
          _filteredSites = List.from(_availableSites);
        });
        
        // Sort sites by distance after loading
        await _sortSitesByDistance();
      }
    } catch (e) {
      print('Error loading sites: $e');
    }
  }

  Future<void> _sortSitesByDistance() async {
    try {
      // Get current location once
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        );
      } catch (e) {
        print('Could not get current location for sorting: $e');
        return; // Keep original order if location unavailable
      }

      // Calculate distances and sort
      List<MapEntry<SiteModel, double>> sitesWithDistance = [];
      
      for (SiteModel site in _availableSites) {
        double distance = double.infinity;
        
        if (site.latitude != null && site.longitude != null) {
          try {
            distance = Geolocator.distanceBetween(
              currentPosition.latitude,
              currentPosition.longitude,
              site.latitude!,
              site.longitude!,
            );
          } catch (e) {
            print('Error calculating distance for ${site.name}: $e');
            distance = double.infinity;
          }
        }
        
        sitesWithDistance.add(MapEntry(site, distance));
      }

      // Sort by distance (nearest first)
      sitesWithDistance.sort((a, b) => a.value.compareTo(b.value));

      // Update the lists
      setState(() {
        _availableSites = sitesWithDistance.map((entry) => entry.key).toList();
        _filteredSites = List.from(_availableSites);
      });
    } catch (e) {
      print('Error sorting sites by distance: $e');
    }
  }



  Future<void> _handlePunchOut() async {
    setState(() {
      _isLoading = true;
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

      // Call saveAttendance API for punch out
      final success = await ApiService.saveAttendance(
        type: 'check_out',
        siteId: '', // Empty for punch out
        address: address,
        remark: '',
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
      );

      if (success) {
        SnackBarUtils.showSuccess(context, message: 'Successfully punched out');
        
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

  Future<void> _showSiteSelectionDialog() async {
    // Load sites if not already loaded
    if (_availableSites.isEmpty) {
      await _loadSites();
    }

    // Reset search and filtered sites
    _searchController.clear();
    _filteredSites = List.from(_availableSites);
    
    // Clear location cache to get fresh data
    _siteLocationCache.clear();
    _cachedPosition = null;

    showDialog(
      context: context,
      builder: (context) => _buildSiteSelectionDialog(),
    );
  }

  Widget _buildSiteSelectionDialog() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Site',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose a site to punch in:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 12),
                            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search sites...',
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (value) {
                  setModalState(() {
                    _filterSitesForModal(value, setModalState);
                  });
                },
              ),
            ),
            SizedBox(height: 12),
            // Check-in from somewhere else option
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Want to checkin from somewhere else?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showRemarkDialog();
                },
              ),
            ),
            SizedBox(height: 12),
                Expanded(
                  child: _filteredSites.isEmpty
                      ? Center(
                          child: Text(
                            'No sites found',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredSites.length,
                          itemBuilder: (context, index) {
                            final site = _filteredSites[index];
                            return _buildSiteItem(site);
                          },
                        ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSiteItem(SiteModel site) {
    return FutureBuilder<String>(
      future: _getSiteLocationStatus(site),
      builder: (context, snapshot) {
        String statusText = 'Loading...';
        Color statusColor = Colors.grey;
        bool canCheckIn = false;

        if (snapshot.hasData) {
          statusText = snapshot.data!;
          if (statusText.contains('You can check in')) {
            statusColor = Colors.green;
            canCheckIn = true;
          } else if (statusText.contains('You\'re at site')) {
            statusColor = Colors.blue;
            canCheckIn = true;
          } else if (statusText.contains('away from site')) {
            statusColor = Colors.orange;
            canCheckIn = false;
          } else if (statusText.contains('Location unavailable')) {
            statusColor = Colors.red;
            canCheckIn = true; // Allow check-in if location unavailable
          }
        }

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              site.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.clientName ?? 'No client',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: statusColor,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        statusText,
                        style: AppTypography.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: canCheckIn 
                ? Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                : Icon(
                    Icons.location_on,
                    color: statusColor,
                  ),
            onTap: () => _handleSiteSelection(site, statusText),
          ),
        );
      },
    );
  }

  Future<String> _getSiteLocationStatus(SiteModel site) async {
    // Check cache first
    if (_siteLocationCache.containsKey(site.id)) {
      return _siteLocationCache[site.id]!;
    }

    try {
      // Check if site has location data
      if (site.latitude == null || site.longitude == null) {
        _siteLocationCache[site.id] = 'You can check in';
        return 'You can check in';
      }

      // Get current location (use cached if available)
      Position currentPosition;
      if (_cachedPosition != null) {
        currentPosition = _cachedPosition!;
      } else {
        try {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          );
          _cachedPosition = currentPosition; // Cache the position
        } catch (locationError) {
          print('Location error for site ${site.name}: $locationError');
          _siteLocationCache[site.id] = 'Location unavailable';
          return 'Location unavailable';
        }
      }

      // Calculate distance
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        site.latitude!,
        site.longitude!,
      );

      double distanceInKm = distanceInMeters / 1000;
      double minRange = (site.minRange ?? 0.1).toDouble(); // Default 100 meters

      String status;
      if (distanceInKm <= minRange) {
        status = 'You\'re at site';
      } else {
        status = 'You\'re ${distanceInKm.toStringAsFixed(1)} km away from site';
      }

      // Cache the result
      _siteLocationCache[site.id] = status;
      return status;
    } catch (e) {
      print('Error calculating site distance: $e');
      _siteLocationCache[site.id] = 'Location unavailable';
      return 'Location unavailable';
    }
  }

  void _handleSiteSelection(SiteModel site, String statusText) {
    if (statusText.contains('You can check in') || 
        statusText.contains('You\'re at site') ||
        statusText.contains('Location unavailable')) {
      // Allow punch in
      Navigator.of(context).pop();
      _performPunchIn(site);
    } else {
      // Show error
      SnackBarUtils.showError(
        context,
        message: 'You must be at the site to punch in',
      );
    }
  }

  void _filterSites(String query) {
    print('Search query: "$query"');
    print('Available sites count: ${_availableSites.length}');
    
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredSites = List.from(_availableSites);
        } else {
          _filteredSites = _availableSites.where((site) {
            final name = site.name.toLowerCase();
            final client = (site.clientName ?? '').toLowerCase();
            final searchQuery = query.toLowerCase();
            final matches = name.contains(searchQuery) || client.contains(searchQuery);
            if (matches) {
              print('Match found: ${site.name} (${site.clientName})');
            }
            return matches;
          }).toList();
        }
      });
      print('Filtered sites count: ${_filteredSites.length}');
    }
  }

  void _filterSitesForModal(String query, StateSetter setModalState) {
    print('Modal search query: "$query"');
    print('Available sites count: ${_availableSites.length}');
    
    if (query.isEmpty) {
      _filteredSites = List.from(_availableSites);
    } else {
      _filteredSites = _availableSites.where((site) {
        final name = site.name.toLowerCase();
        final client = (site.clientName ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();
        final matches = name.contains(searchQuery) || client.contains(searchQuery);
        if (matches) {
          print('Modal match found: ${site.name} (${site.clientName})');
        }
        return matches;
      }).toList();
    }
    print('Modal filtered sites count: ${_filteredSites.length}');
  }

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
    setState(() {
      _isLoading = true;
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
      );

      if (success) {
        SnackBarUtils.showSuccess(
          context, 
          message: 'Successfully checked in from remote location',
        );
        
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

  Future<void> _performPunchIn(SiteModel site) async {
    setState(() {
      _isLoading = true;
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

      // Call saveAttendance API
      final success = await ApiService.saveAttendance(
        type: 'check_in',
        siteId: site.id.toString(),
        address: address,
        remark: '',
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
      );

      if (success) {
        SnackBarUtils.showSuccess(
          context, 
          message: 'Successfully checked in at ${site.name}',
        );
        
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : SingleChildScrollView(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance Card with custom punch-in handler
                  AttendanceCard(
                    key: _attendanceCardKey,
                    onPunchInPressed: _showSiteSelectionDialog,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Punch Out Button (shown when user is checked in)
                  if (!_showPunchInForm) ...[
                    _buildPunchOutButton(),
                  ],
                ],
              ),
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



