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
  
  bool _isLoading = false;
  bool _showPunchInForm = false;
  SiteModel? _selectedSite;
  List<SiteModel> _availableSites = [];
  List<SiteModel> _filteredSites = [];

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
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _attendanceService.checkAttendance();
      if (success) {
        // Determine if we should show punch-in form
        _showPunchInForm = _attendanceService.needsCheckIn;
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to load attendance status');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      }
    } catch (e) {
      print('Error loading sites: $e');
    }
  }



  Future<void> _handlePunchOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Call punch-out API
      await Future.delayed(Duration(seconds: 2)); // Simulate API call
      
      SnackBarUtils.showSuccess(context, message: 'Successfully punched out');
      
      // Refresh attendance status
      await _loadAttendanceStatus();
      
      // Navigate back
      NavigationUtils.pop(context);
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to punch out');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search sites...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.location_on_outlined,
                  color: Colors.blue[600],
                ),
                title: Text(
                  'Want to checkin from somewhere else?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue[600],
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
                              color: AppColors.textSecondary,
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

        if (snapshot.hasData) {
          statusText = snapshot.data!;
          if (statusText.contains('You can check in')) {
            statusColor = Colors.green;
          } else if (statusText.contains('You\'re at site')) {
            statusColor = Colors.blue;
          } else if (statusText.contains('away from site')) {
            statusColor = Colors.orange;
          }
        }

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              site.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.clientName ?? 'No client',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  statusText,
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Icon(
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
    try {
      // Check if site has location data
      if (site.latitude == null || site.longitude == null) {
        return 'You can check in';
      }

      // Get current location
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Calculate distance
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        site.latitude!,
        site.longitude!,
      );

      double distanceInKm = distanceInMeters / 1000;
      double minRange = (site.minRange ?? 0.1).toDouble(); // Default 100 meters

      if (distanceInKm <= minRange) {
        return 'You\'re at site';
      } else {
        return 'You\'re ${distanceInKm.toStringAsFixed(1)} km away from site';
      }
    } catch (e) {
      return 'Location unavailable';
    }
  }

  void _handleSiteSelection(SiteModel site, String statusText) {
    if (statusText.contains('You can check in') || statusText.contains('You\'re at site')) {
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
                color: AppColors.textSecondary,
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
        
        // Refresh attendance status
        await _loadAttendanceStatus();
        
        // Navigate back
        NavigationUtils.pop(context);
      } else {
        SnackBarUtils.showError(context, message: 'Failed to check in from remote location');
      }
    } catch (e) {
      print('Error during remote check-in: $e');
      SnackBarUtils.showError(context, message: 'Failed to check in: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performPunchIn(SiteModel site) async {
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
        
        // Refresh attendance status
        await _loadAttendanceStatus();
        
        // Navigate back
        NavigationUtils.pop(context);
      } else {
        SnackBarUtils.showError(context, message: 'Failed to check in');
      }
    } catch (e) {
      print('Error during check-in: $e');
      SnackBarUtils.showError(context, message: 'Failed to check in: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        title: 'Attendance',
        showBackButton: false,
        showDrawer: true,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
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
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance Card with custom punch-in handler
                  AttendanceCard(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: 12),
          
          Text(
            'You are currently checked in. Tap the button below to punch out.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          SizedBox(height: 20),
          
          CustomButton(
            text: 'Punch Out',
            onPressed: _isLoading ? null : _handlePunchOut,
            isLoading: _isLoading,
            backgroundColor: AppColors.errorColor,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}



