import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:card_swiper/card_swiper.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/session_manager.dart';
import '../models/site_model.dart';
import '../services/site_update_service.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/site_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/image_picker_utils.dart';

class SiteDetailsScreen extends StatefulWidget {
  final SiteModel site;
  final Function(SiteModel)? onSiteUpdated;

  const SiteDetailsScreen({super.key, required this.site, this.onSiteUpdated});

  @override
  State<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends State<SiteDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isEditMode = false;
  bool _isLocationEditMode = false;
  bool _isLoading = false;
  final SiteUpdateService _siteUpdateService = SiteUpdateService();

  // Current site data (can be updated)
  late SiteModel _currentSite;

  // Controllers for edit mode
  late TextEditingController _siteNameController;
  late TextEditingController _clientNameController;
  late TextEditingController _architectNameController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _minRangeController;
  late TextEditingController _maxRangeController;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  // Selected images for upload
  List<File> _selectedImages = [];

  // Loading state for image upload
  bool _isUploadingImages = false;

  // Map controller
  GoogleMapController? _mapController;

  // Location state for editing
  LatLng? _currentLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _currentSite = widget.site;
    _initializeControllers();
    _initializeLocation();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _siteNameController = TextEditingController(text: _currentSite.name);
    _clientNameController = TextEditingController(
      text: _currentSite.clientName ?? '',
    );
    _architectNameController = TextEditingController(
      text: _currentSite.architectName ?? '',
    );
    _addressController = TextEditingController(
      text: _currentSite.address ?? '',
    );
    _latitudeController = TextEditingController(
      text: _currentSite.latitude != null
          ? _currentSite.latitude!.toStringAsFixed(6)
          : '',
    );
    _longitudeController = TextEditingController(
      text: _currentSite.longitude != null
          ? _currentSite.longitude!.toStringAsFixed(6)
          : '',
    );
    _startDateController = TextEditingController(
      text: _currentSite.startDate ?? '',
    );
    _endDateController = TextEditingController(
      text: _currentSite.endDate ?? '',
    );
    _minRangeController = TextEditingController(
      text: _currentSite.minRange.toString(),
    );
    _maxRangeController = TextEditingController(
      text: _currentSite.maxRange.toString(),
    );
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  void _disposeControllers() {
    _siteNameController.dispose();
    _clientNameController.dispose();
    _architectNameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _minRangeController.dispose();
    _maxRangeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
  }

  void _initializeLocation() {
    if (_currentSite.latitude != null && _currentSite.longitude != null) {
      _currentLocation = LatLng(
        _currentSite.latitude!,
        _currentSite.longitude!,
      );
    }
    _updateMarkers();
  }

  void _updateMarkers() {
    if (_currentLocation != null) {
      _markers = {
        Marker(
          markerId: MarkerId('site_${_currentSite.id}'),
          position: _currentLocation!,
          infoWindow: InfoWindow(
            title: _currentSite.name,
            snippet: _currentSite.address ?? 'Site location',
          ),
          draggable: _isLocationEditMode,
          onDragEnd: _isLocationEditMode ? _onMarkerDragEnd : null,
        ),
      };
    } else {
      _markers = {};
    }
  }

  void _onMarkerDragEnd(LatLng newPosition) {
    setState(() {
      _currentLocation = newPosition;
      _updateMarkers();
      // Update the text controllers
      _latitudeController.text = newPosition.latitude.toStringAsFixed(6);
      _longitudeController.text = newPosition.longitude.toStringAsFixed(6);
    });

    // Get address from coordinates
    _getAddressFromCoordinates(newPosition);
  }

  void _onMapTap(LatLng position) {
    if (_isLocationEditMode) {
      // Dismiss keyboard when tapping on map
      _dismissKeyboard();
      
      setState(() {
        _currentLocation = position;
        _updateMarkers();
        // Update the text controllers
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      // Get address from coordinates
      _getAddressFromCoordinates(position);
    }
  }

  void _dismissKeyboard() {
    // Multiple methods to ensure keyboard is dismissed
    FocusScope.of(context).unfocus();
    _searchFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> _onPlaceSelected(Prediction prediction) async {
    try {
      // Dismiss keyboard and clear search field immediately
      _dismissKeyboard();
      _searchController.clear();
      
      setState(() {
        _isLoading = true;
      });

      // Get place details using Google Places API
      final String apiKey = "AIzaSyBdsNUr3ZUSZH63Mb2brR1LqAmZnIP94zQ";
      final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final geometry = result['geometry'];
          final location = geometry['location'];
          
          final lat = location['lat'].toDouble();
          final lng = location['lng'].toDouble();
          
          setState(() {
            _currentLocation = LatLng(lat, lng);
            _latitudeController.text = lat.toStringAsFixed(6);
            _longitudeController.text = lng.toStringAsFixed(6);
            _addressController.text = result['formatted_address'] ?? prediction.description ?? '';
            _updateMarkers();
            _isLoading = false;
          });

          // Animate camera to selected location
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(lat, lng),
                15.0,
              ),
            );
          }

          SnackBarUtils.showSuccess(
            context,
            message: 'Location selected successfully!',
          );
        } else {
          throw Exception('Place details not found');
        }
      } else {
        throw Exception('Failed to fetch place details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to get place details: $e',
      );
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
    }
  }

  Future<void> _saveAddressChanges() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _siteUpdateService.updateSite(
      siteId: _currentSite.id,
      address: _addressController.text.trim(),
      latitude: _latitudeController.text.trim().isNotEmpty
          ? double.tryParse(_latitudeController.text.trim())
          : null,
      longitude: _longitudeController.text.trim().isNotEmpty
          ? double.tryParse(_longitudeController.text.trim())
          : null,
      minRange: int.tryParse(_minRangeController.text.trim()),
      maxRange: int.tryParse(_maxRangeController.text.trim()),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Update the current site with new data
      final updatedSite = _siteUpdateService.updatedSite;
      if (updatedSite != null) {
        setState(() {
          _currentSite = updatedSite;
        });

        // Notify parent widget about the update
        widget.onSiteUpdated?.call(_currentSite);
      } else {
        // If API didn't return updated data, create updated site manually
        final manuallyUpdatedSite = _currentSite.copyWith(
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          latitude: _latitudeController.text.trim().isNotEmpty
              ? double.tryParse(_latitudeController.text.trim())
              : null,
          longitude: _longitudeController.text.trim().isNotEmpty
              ? double.tryParse(_longitudeController.text.trim())
              : null,
          minRange: int.tryParse(_minRangeController.text.trim()) ?? _currentSite.minRange,
          maxRange: int.tryParse(_maxRangeController.text.trim()) ?? _currentSite.maxRange,
        );

        setState(() {
          _currentSite = manuallyUpdatedSite;
        });

        // Notify parent widget about the update
        widget.onSiteUpdated?.call(_currentSite);
      }

      SnackBarUtils.showSuccess(
        context,
        message: 'Location updated successfully!',
      );
      
      setState(() {
        _isLocationEditMode = false;
      });
    } else {
      SnackBarUtils.showError(
        context,
        message: _siteUpdateService.errorMessage,
      );
    }
  }

  void _onCoordinateChanged() {
    // Update map when coordinates are manually changed
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();

    if (latText.isNotEmpty && lngText.isNotEmpty) {
      final lat = double.tryParse(latText);
      final lng = double.tryParse(lngText);

      if (lat != null && lng != null) {
        setState(() {
          _currentLocation = LatLng(lat, lng);
          _updateMarkers();
        });
      }
    }
  }

  Widget _buildLocationInfoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
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
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Reset controllers to current values when canceling edit
        _initializeControllers();
        // Clear selected images when canceling edit
        _selectedImages.clear();
      }
    });
  }

  void _toggleLocationEditMode() {
    setState(() {
      _isLocationEditMode = !_isLocationEditMode;
      if (!_isLocationEditMode) {
        // Reset location controllers to current values when canceling edit
        _addressController.text = _currentSite.address ?? '';
        _latitudeController.text = _currentSite.latitude != null
            ? _currentSite.latitude!.toStringAsFixed(6)
            : '';
        _longitudeController.text = _currentSite.longitude != null
            ? _currentSite.longitude!.toStringAsFixed(6)
            : '';
        _minRangeController.text = _currentSite.minRange.toString();
        _maxRangeController.text = _currentSite.maxRange.toString();
        // Reset location to original values
        _initializeLocation();
      } else {
        // Enable marker dragging in location edit mode
        _updateMarkers();
      }
    });
  }

  void _showImagePicker(BuildContext context) async {
    // Dismiss keyboard when opening image picker
    _dismissKeyboard();
    
    final List<File> images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: true,
      maxImages: 10,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
      });

      // Upload images automatically
      await _uploadImages();
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isUploadingImages = true;
    });

    final success = await _siteUpdateService.updateSite(
      siteId: _currentSite.id,
      images: _selectedImages,
    );

    setState(() {
      _isLoading = false;
      _isUploadingImages = false;
    });

    if (success) {
      // Clear selected images after successful upload
      setState(() {
        _selectedImages.clear();
      });

      SnackBarUtils.showSuccess(
        context,
        message: 'Images uploaded successfully!',
      );

      // Refresh the site data to show new images
      await _refreshSiteData();
    } else {
      SnackBarUtils.showError(
        context,
        message: _siteUpdateService.errorMessage,
      );
    }
  }

  Future<void> _refreshSiteData() async {
    try {
      // Get updated site data from API
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) return;

      // Call API to get updated site data
      final siteListResponse = await ApiService.getSiteList(apiToken: apiToken);

      if (siteListResponse.isSuccess) {
        // Find the current site in the updated list
        final sites = siteListResponse.data;
        final updatedSite = sites.cast<SiteModel?>().firstWhere(
          (site) => site?.id == _currentSite.id,
          orElse: () => null,
        );

        if (updatedSite != null) {
          // Update the current site with new data
          setState(() {
            _currentSite = updatedSite;
          });

          // Update the site in SiteService as well
          SiteService.updateSite(updatedSite);

          // Notify parent widget about the update
          widget.onSiteUpdated?.call(updatedSite);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing site data: $e');
    }
  }

  Future<void> _editImage(BuildContext context, int imageId) async {
    // Dismiss keyboard when opening image picker
    _dismissKeyboard();
    
    // Show image source selection dialog
    final List<File> images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: false, // Single image for replacement
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String? apiToken = await LocalStorageService.getToken();
        if (apiToken == null) {
          SnackBarUtils.showError(
            context,
            message: 'Authentication token not found',
          );
          return;
        }

        // Call updateSiteImage API
        final success = await _updateSiteImage(apiToken, imageId, images.first);

        if (success) {
          SnackBarUtils.showSuccess(
            context,
            message: 'Image updated successfully!',
          );
          // Refresh site data to show updated image
          await _refreshSiteData();
        }
      } catch (e) {
        SnackBarUtils.showError(context, message: 'Failed to update image: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteImage(BuildContext context, int imageId) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String? apiToken = await LocalStorageService.getToken();
        if (apiToken != null) {
          // Call deleteSiteImage API
          final success = await _deleteSiteImage(apiToken, imageId);

          if (success) {
            SnackBarUtils.showSuccess(
              context,
              message: 'Image deleted successfully!',
            );
            // Refresh site data to remove deleted image
            await _refreshSiteData();
          }
        } else {
          SnackBarUtils.showError(
            context,
            message: 'Authentication token not found',
          );
        }
      } catch (e) {
        SnackBarUtils.showError(context, message: 'Failed to delete image: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _updateSiteImage(
    String apiToken,
    int imageId,
    File newImage,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/updateSiteImage'),
      );

      // Add form fields
      request.fields['api_token'] = apiToken;
      request.fields['site_id'] = _currentSite.id.toString();
      request.fields['image_id'] = imageId.toString();

      // Add image file
      final stream = http.ByteStream(newImage.openRead());
      final length = await newImage.length();
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: newImage.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(ApiService.timeout);
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['status'] == 1;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating site image: $e');
      return false;
    }
  }

  Future<bool> _deleteSiteImage(String apiToken, int imageId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/api/deleteSiteImage'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {'api_token': apiToken, 'image_id': imageId.toString()},
          )
          .timeout(ApiService.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['status'] == 1;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting site image: $e');
      return false;
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

          final success = await _siteUpdateService.updateSite(
        siteId: _currentSite.id,
        siteName: _siteNameController.text.trim(),
        clientName: _clientNameController.text.trim(),
        architectName: _architectNameController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
      );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Update the current site with new data
      final updatedSite = _siteUpdateService.updatedSite;
      if (updatedSite != null) {
        setState(() {
          _currentSite = updatedSite;
        });

        // Notify parent widget about the update
        widget.onSiteUpdated?.call(_currentSite);
      } else {
        // If API didn't return updated data, create updated site manually
        final manuallyUpdatedSite = _currentSite.copyWith(
          name: _siteNameController.text.trim(),
          clientName: _clientNameController.text.trim().isEmpty
              ? null
              : _clientNameController.text.trim(),
          architectName: _architectNameController.text.trim().isEmpty
              ? null
              : _architectNameController.text.trim(),
          startDate: _startDateController.text.trim().isEmpty
              ? null
              : _startDateController.text.trim(),
          endDate: _endDateController.text.trim().isEmpty
              ? null
              : _endDateController.text.trim(),
        );

        setState(() {
          _currentSite = manuallyUpdatedSite;
        });

        // Notify parent widget about the update
        widget.onSiteUpdated?.call(_currentSite);
      }

      SnackBarUtils.showSuccess(
        context,
        message: 'Site details updated successfully!',
      );
      setState(() {
        _isEditMode = false;
      });
    } else {
      // Check for session expiration
      if (_siteUpdateService.errorMessage.contains('Session expired')) {
        await SessionManager.handleSessionExpired(context);
      } else {
        SnackBarUtils.showError(
          context,
          message: _siteUpdateService.errorMessage,
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (_currentSite.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'complete':
        return Colors.blue;
      case 'overdue':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 60,
              tablet: 80,
              desktop: 100,
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
            'No Image',
            style: AppTypography.bodyLarge.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImagePicker(context),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 8,
            tablet: 12,
            desktop: 16,
          ),
        ),
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
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 60,
                tablet: 80,
                desktop: 100,
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
              'Add Image',
              style: AppTypography.bodyLarge.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
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
              'Tap to upload new images',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
        ),
      ),
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
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading icon
          SizedBox(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 60,
              tablet: 80,
              desktop: 100,
            ),
            height: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 60,
              tablet: 80,
              desktop: 100,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
              'Uploading Images...',
              style: AppTypography.bodyLarge.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
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
              'Please wait while your images are being uploaded',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, String imageUrl, int imageId) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder(context);
              },
            ),
            // Edit and Delete Icons
            Positioned(
              top: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ),
              right: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Icon
                  GestureDetector(
                    onTap: () => _editImage(context, imageId),
                    child: Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 6,
                          tablet: 8,
                          desktop: 10,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                  ),
                  // Delete Icon
                  GestureDetector(
                    onTap: () => _deleteImage(context, imageId),
                    child: Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 6,
                          tablet: 8,
                          desktop: 10,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 100,
              tablet: 120,
              desktop: 140,
            ),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? Container(
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
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 6,
                          tablet: 8,
                          desktop: 10,
                        ),
                      ),
                    ),
                    child: Text(
                      value.toUpperCase(),
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                                    color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
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
          CustomTextField(
            controller: controller,
            label: '',
            // Remove duplicate label
            hintText: 'Enter $label',
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            onChanged: (label == 'Latitude' || label == 'Longitude')
                ? (value) => _onCoordinateChanged()
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 8,
          tablet: 12,
          desktop: 16,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 100,
              tablet: 120,
              desktop: 140,
            ),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: CustomDatePickerField(
              controller: controller,
              label: label,
              hintText: 'Select $label',
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showSiteLocation() async {
    if (_currentSite.latitude != null && _currentSite.longitude != null) {
      final siteLocation = LatLng(_currentSite.latitude!, _currentSite.longitude!);
      
      // Animate camera to site location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(siteLocation, 15.0),
        );
      }
      
      SnackBarUtils.showSuccess(
        context,
        message: 'Showing site location',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: 'Site location not available',
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Dismiss keyboard when getting current location
      _dismissKeyboard();
      
      setState(() {
        _isLoading = true;
      });

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          SnackBarUtils.showError(
            context,
            message:
                'Location permission denied. Please enable location access in settings.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(
          context,
          message:
              'Location permission permanently denied. Please enable location access in app settings.',
        );
        return;
      }

      // Get current location using geolocator
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isLoading = false;
      });

      // Only animate camera to current location - do not update fields
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
        message: 'Showing current location on map',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to get current location: $e',
      );
    }
  }

  void _showFullScreenMap() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _FullScreenMapDialog(
          currentLocation: _currentLocation ?? 
              (_currentSite.latitude != null && _currentSite.longitude != null
                  ? LatLng(_currentSite.latitude!, _currentSite.longitude!)
                  : const LatLng(20.5937, 78.9629)),
          siteName: _currentSite.name,
          onLocationSelected: (LatLng location, String address) {
            // Update the current location and address
            setState(() {
              _currentLocation = location;
              _latitudeController.text = location.latitude.toStringAsFixed(6);
              _longitudeController.text = location.longitude.toStringAsFixed(6);
              _addressController.text = address;
              _updateMarkers();
            });
            
            SnackBarUtils.showSuccess(
              context,
              message: 'Location updated successfully!',
            );
          },
        );
      },
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:EdgeInsets.symmetric(horizontal: 10),
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
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Fields Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Field
              if (_isEditMode) ...[
                _buildEditableRow(context, 'Address', _addressController),
              ] else ...[
                if (_currentSite.address != null &&
                    _currentSite.address!.isNotEmpty)
                  _buildLocationInfoRow(
                    context,
                    'Address',
                    _currentSite.address!,
                  ),
              ],

              // Latitude and Longitude Fields
              if (_isLocationEditMode) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableRow(
                        context,
                        'Latitude',
                        _latitudeController,
                        isNumber: true,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildEditableRow(
                        context,
                        'Longitude',
                        _longitudeController,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                if (_currentSite.latitude != null &&
                    _currentSite.longitude != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocationInfoRow(
                          context,
                          'Latitude',
                          _currentSite.latitude!.toStringAsFixed(6),
                        ),
                      ),
                      Expanded(
                        child: _buildLocationInfoRow(
                          context,
                          'Longitude',
                          _currentSite.longitude!.toStringAsFixed(6),
                        ),
                      ),
                    ],
                  ),

                ],
              ],

              // Min and Max Range Fields
              if (_isLocationEditMode) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableRow(
                        context,
                        'Min Range',
                        _minRangeController,
                        isNumber: true,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildEditableRow(
                        context,
                        'Max Range',
                        _maxRangeController,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildLocationInfoRow(
                        context,
                        'Min Range',
                        '${_currentSite.minRange}',
                      ),
                    ),
                    Expanded(
                      child: _buildLocationInfoRow(
                        context,
                        'Max Range',
                        '${_currentSite.maxRange}',
                      ),
                    ),
                  ],
                ),

              ],

              // Show message if no location data in view mode
              if (!_isEditMode &&
                  (_currentSite.address == null ||
                      _currentSite.address!.isEmpty) &&
                  (_currentSite.latitude == null ||
                      _currentSite.longitude == null))
                _buildLocationInfoRow(
                  context,
                  'Status',
                  'Location not specified',
                ),
            ],
          ),


          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 8,
              tablet: 10,
              desktop: 12,
            ),
          ),

          // Search Location Section (only in edit mode)
          if (_isLocationEditMode) ...[
            Text(
              'Search Location',
              style: AppTypography.titleMedium.copyWith(
                fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              focusNode: _searchFocusNode,
              googleAPIKey: "AIzaSyBdsNUr3ZUSZH63Mb2brR1LqAmZnIP94zQ",
              inputDecoration: InputDecoration(
                hintText: 'Search for a place...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                  ),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                  ),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                  ),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                  ),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                  vertical: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                ),
              ),
              debounceTime: 600,
              countries: ["in"], // Restrict to India
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (prediction) {
                _onPlaceSelected(prediction);
              },
              itemClick: (prediction) {
                _onPlaceSelected(prediction);
              },
              itemBuilder: (context, index, prediction) {
                return Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderColor.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: ResponsiveUtils.responsiveFontSize(context, mobile: 20, tablet: 22, desktop: 24),
                      ),
                      SizedBox(width: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prediction.description ?? '',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (prediction.structuredFormatting?.secondaryText != null) ...[
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                              Text(
                                prediction.structuredFormatting!.secondaryText!,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              seperatedBuilder: Divider(
                height: 1,
                color: AppColors.borderColor.withOpacity(0.5),
              ),
              containerHorizontalPadding: 0,
              containerVerticalPadding: 0,
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          ],
                     // Map Section
           GestureDetector(
             onPanUpdate: (details) {
               // Prevent screen scroll when panning on map
             },
             child: SizedBox(
               width: double.infinity,
               height: ResponsiveUtils.responsiveFontSize(
                 context,
                 mobile: 250,
                 tablet: 300,
                 desktop: 350,
               ),
               child: Stack(
                 children: [
                   ClipRRect(
                     borderRadius: BorderRadius.circular(
                       ResponsiveUtils.responsiveSpacing(
                         context,
                         mobile: 12,
                         tablet: 16,
                         desktop: 20,
                       ),
                     ),
                     child: _buildMapWidget(context),
                   ),
                   // Map control buttons positioned outside ClipRRect
                   _buildMapControls(context),
                 ],
               ),
             ),
           ),

          if (_isLocationEditMode) ...[
            SizedBox(
              height: ResponsiveUtils.responsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            CustomButton(
              text: 'Save Address',
              onPressed: _saveAddressChanges,
              width: double.infinity,
              prefixIcon: Icon(
                Icons.location_on,
                color: Colors.white,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapWidget(BuildContext context) {
    // Always show map - if no coordinates, show default location (India center)
    final defaultLocation = LatLng(20.5937, 78.9629); // India center
    final targetLocation =
        _currentLocation ??
        (_currentSite.latitude != null && _currentSite.longitude != null
            ? LatLng(_currentSite.latitude!, _currentSite.longitude!)
            : defaultLocation);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: targetLocation,
        zoom: _currentSite.latitude != null && _currentSite.longitude != null
            ? 15.0
            : 5.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      onTap: _onMapTap,
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // Disable default location button
      zoomControlsEnabled: false, // Disable default zoom controls
      mapToolbarEnabled: false,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }

  Widget _buildMapControls(BuildContext context) {
    return Stack(
      children: [
        // Zoom controls - top right
        Positioned(
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
                  color: AppColors.textWhite,
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
                      color: AppColors.shadowColor.withOpacity(0.2),
                      blurRadius: 8,
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
                  color: AppColors.textWhite,
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
                      color: AppColors.shadowColor.withOpacity(0.2),
                      blurRadius: 8,
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
        ),
        
        // Location buttons - bottom right
        Positioned(
          right: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
          bottom: ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
          child: Column(
            children: [
              // Show Site Location Button (Pin icon)
              if (_currentSite.latitude != null && _currentSite.longitude != null)
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
                    color: AppColors.textWhite,
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
                        color: AppColors.shadowColor.withOpacity(0.2),
                        blurRadius: 8,
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
                      onTap: _showSiteLocation,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
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
              
              if (_currentSite.latitude != null && _currentSite.longitude != null)
                SizedBox(
                  height: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
              
              // Current Location Button (My Location)
              if (_isLocationEditMode)
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
                    color: AppColors.textWhite,
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
                        color: AppColors.shadowColor.withOpacity(0.2),
                        blurRadius: 8,
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
                      onTap: _useCurrentLocation,
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
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final images = _currentSite.images;
    final hasImages = images.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        // Dismiss keyboard when back button is pressed
        _dismissKeyboard();
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Site Details',
          showDrawer: false,
          showBackButton: true,
        ),
        body: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping anywhere on the screen
            _dismissKeyboard();
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 15),

            SizedBox(
              height: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 250,
                tablet: 300,
                desktop: 350,
              ),
              child: _isUploadingImages
                  ? _buildUploadingPlaceholder(context)
                  : Swiper(
                      itemCount: hasImages ? images.length + 1 : 1,
                      // +1 for add image card
                      itemBuilder: (context, index) {
                        if (hasImages && index < images.length) {
                          // Show existing image
                          return _buildImageCard(
                            context,
                            images[index].imagePath,
                            images[index].id,
                          );
                        } else {
                          // Show add image card
                          return _buildAddImageCard(context);
                        }
                      },
                      onIndexChanged: (index) {
                        setState(() {
                          if (hasImages && index < images.length) {
                            _currentImageIndex = index;
                          } else {
                            _currentImageIndex =
                                -1; // Add image card is selected
                          }
                        });
                      },
                      pagination: const SwiperPagination(),
                      control: const SwiperControl(),
                      autoplay: hasImages && images.length > 1,
                      autoplayDelay: 3000,
                    ),
            ),

            if (hasImages)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 12,
                    desktop: 16,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_currentImageIndex >= 0 ? _currentImageIndex + 1 : images.length} / ${images.length}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // Site Information
            Padding(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSite.name,
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 20,
                        tablet: 24,
                        desktop: 28,
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
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

                  // Progress Section
                  Container(
                    width: double.infinity,
                    padding: ResponsiveUtils.responsivePadding(context),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.responsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 20,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Progress',
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_currentSite.progress}%',
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 8,
                            tablet: 12,
                            desktop: 16,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: _currentSite.progress / 100,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 8,
                            tablet: 10,
                            desktop: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 24,
                      tablet: 32,
                      desktop: 40,
                    ),
                  ),

                  // Site Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                                              Text(
                          'Site Information',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      TextButton(onPressed: _toggleEditMode, child: Text(_isEditMode ? 'Cancel' : 'Edit Info',)),

                    ],
                  ),

                  Container(
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
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          'Status',
                          _currentSite.status,
                          isStatus: true,
                        ),
                        if (_isEditMode) ...[
                          _buildEditableRow(
                            context,
                            'Site Name',
                            _siteNameController,
                          ),
                          _buildEditableRow(
                            context,
                            'Client Name',
                            _clientNameController,
                          ),
                          _buildEditableRow(
                            context,
                            'Architect Name',
                            _architectNameController,
                          ),
                          _buildDatePickerRow(
                            context,
                            'Start Date',
                            _startDateController,
                          ),
                          _buildDatePickerRow(
                            context,
                            'End Date',
                            _endDateController,
                          ),

                        ] else ...[
                          _buildInfoRow(
                            context,
                            'Site Name',
                            _currentSite.name,
                          ),
                          _buildInfoRow(
                            context,
                            'Client Name',
                            _currentSite.clientName ?? 'Not specified',
                          ),
                          _buildInfoRow(
                            context,
                            'Architect Name',
                            _currentSite.architectName ?? 'Not specified',
                          ),
                          _buildInfoRow(
                            context,
                            'Start Date',
                            _currentSite.startDate ?? 'Not set',
                          ),
                          _buildInfoRow(
                            context,
                            'End Date',
                            _currentSite.endDate ?? 'Not set',
                          ),

                        ],
                        _buildInfoRow(context, 'Company', _currentSite.company),
                      ],
                    ),
                  ),

                  // Save Button (only in edit mode)
                  if (_isEditMode) ...[
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _isLoading ? null : _saveChanges,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                  ],

                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 24,
                      tablet: 32,
                      desktop: 40,
                    ),
                  ),

                  // Location Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                                              Text(
                          'Location',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _showFullScreenMap,
                            child: Text('Select and View Map'),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: _toggleLocationEditMode, 
                            child: Text(_isLocationEditMode ? 'Cancel' : 'Edit Location'),
                          ),
                        ],
                      ),

                    ],
                  ),





                  // Map Section
                  _buildMapSection(context),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 24,
                      tablet: 32,
                      desktop: 40,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      )));
  }
}

class _FullScreenMapDialog extends StatefulWidget {
  final LatLng currentLocation;
  final String siteName;
  final Function(LatLng location, String address) onLocationSelected;

  const _FullScreenMapDialog({
    required this.currentLocation,
    required this.siteName,
    required this.onLocationSelected,
  });

  @override
  State<_FullScreenMapDialog> createState() => _FullScreenMapDialogState();
}

class _FullScreenMapDialogState extends State<_FullScreenMapDialog> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _updateMarkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateMarkers() {
    _markers.clear();
    if (_selectedLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          draggable: true,
          onDragEnd: (LatLng position) async {
            setState(() {
              _selectedLocation = position;
              _updateMarkers();
            });
            
            // Get address from new coordinates
            try {
              List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude,
                position.longitude,
              );
              if (placemarks.isNotEmpty) {
                Placemark place = placemarks[0];
                String address = [
                  place.street,
                  place.subLocality,
                  place.locality,
                  place.administrativeArea,
                  place.postalCode,
                  place.country,
                ].where((element) => element != null && element.isNotEmpty).join(', ');
                
                SnackBarUtils.showSuccess(
                  context,
                  message: 'Location updated: $address',
                );
              }
            } catch (e) {
              debugPrint('Error getting address: $e');
            }
          },
        ),
      );
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    _searchFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> _onPlaceSelected(Prediction prediction) async {
    try {
      _dismissKeyboard();
      _searchController.clear();
      
      setState(() {
        _isLoading = true;
      });

      final String apiKey = "AIzaSyBdsNUr3ZUSZH63Mb2brR1LqAmZnIP94zQ";
      final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final geometry = result['geometry'];
          final location = geometry['location'];
          
          final lat = location['lat'].toDouble();
          final lng = location['lng'].toDouble();
          
          setState(() {
            _selectedLocation = LatLng(lat, lng);
            _updateMarkers();
            _isLoading = false;
          });

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(lat, lng),
                15.0,
              ),
            );
          }

          SnackBarUtils.showSuccess(
            context,
            message: 'Location selected successfully!',
          );
        } else {
          throw Exception('Place details not found');
        }
      } else {
        throw Exception('Failed to fetch place details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to get place details: $e',
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _dismissKeyboard();
      
      setState(() {
        _isLoading = true;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          SnackBarUtils.showError(
            context,
            message: 'Location permission denied. Please enable location access in settings.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(
          context,
          message: 'Location permission permanently denied. Please enable location access in app settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isLoading = false;
      });

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
        message: 'Showing current location on map',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to get current location: $e',
      );
    }
  }

  void _selectLocation() {
    if (_selectedLocation != null) {
      // Get address from coordinates
      _getAddressFromCoordinates(_selectedLocation!);
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        widget.onLocationSelected(_selectedLocation!, address);
        Navigator.of(context).pop();
      } else {
        widget.onLocationSelected(_selectedLocation!, 'Selected Location');
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      widget.onLocationSelected(_selectedLocation!, 'Selected Location');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Select Location - ${widget.siteName}'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _selectLocation,
              child: Text(
                'SELECT',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation,
                zoom: 15.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: (LatLng position) {
                _dismissKeyboard();
                setState(() {
                  _selectedLocation = position;
                  _updateMarkers();
                });
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
            ),
            
            // Search Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchController,
                  focusNode: _searchFocusNode,
                  googleAPIKey: "AIzaSyBdsNUr3ZUSZH63Mb2brR1LqAmZnIP94zQ",
                  inputDecoration: InputDecoration(
                    hintText: 'Search for a place...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  debounceTime: 600,
                  countries: ["in"],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (prediction) {
                    _onPlaceSelected(prediction);
                  },
                  itemClick: (prediction) {
                    _onPlaceSelected(prediction);
                  },
                  itemBuilder: (context, index, prediction) {
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.borderColor.withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prediction.description ?? '',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (prediction.structuredFormatting?.secondaryText != null) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    prediction.structuredFormatting!.secondaryText!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  seperatedBuilder: Divider(
                    height: 1,
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                  containerHorizontalPadding: 0,
                  containerVerticalPadding: 0,
                ),
              ),
            ),
            
            // Map Controls
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: [
                  // Current Location Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _getCurrentLocation,
                        child: Icon(
                          Icons.my_location,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Zoom In Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Zoom Out Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                        child: Icon(
                          Icons.remove,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading Indicator
            if (_isLoading)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
