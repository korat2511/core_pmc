import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/image_picker_utils.dart';
import '../core/utils/date_picker_utils.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/dismiss_keyboard.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateSiteScreen extends StatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  State<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends State<CreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _architectNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _minRangeController = TextEditingController();
  final _maxRangeController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedImages = [];
  bool _isLoading = false;
  
  // Map and location variables
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void dispose() {
    _siteNameController.dispose();
    _clientNameController.dispose();
    _architectNameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _minRangeController.dispose();
    _maxRangeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final String? selectedDate = await DatePickerUtils.pickDate(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // Allow dates from last 5 years
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (selectedDate != null) {
      final DateTime? parsedDate = DatePickerUtils.parseDate(selectedDate);
      if (parsedDate != null && parsedDate != _startDate) {
        setState(() {
          _startDate = parsedDate;
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    final String? selectedDate = await DatePickerUtils.pickDate(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365 * 5)), // If start date selected, use it; otherwise allow from last 5 years
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (selectedDate != null) {
      final DateTime? parsedDate = DatePickerUtils.parseDate(selectedDate);
      if (parsedDate != null && parsedDate != _endDate) {
        setState(() {
          _endDate = parsedDate;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final List<File> images = await ImagePickerUtils.pickMultipleImagesFromGallery();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((file) => file.path).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _dismissKeyboard() {
    // Multiple methods to ensure keyboard is dismissed
    FocusScope.of(context).unfocus();
    _searchFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> _showFullScreenMap() async {
    // Determine initial location: selected location or user's current location
    LatLng initialLocation;
    
    if (_selectedLocation != null) {
      // Use selected location from small map
      initialLocation = _selectedLocation!;
    } else {
      // Get user's current location
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.deniedForever) {
          SnackBarUtils.showError(
            context,
            message: 'Location permission permanently denied. Please enable location access in app settings.',
          );
          return;
        }
        
        if (permission == LocationPermission.denied) {
          SnackBarUtils.showError(
            context,
            message: 'Location permission denied. Please enable location access in settings.',
          );
          return;
        }
        
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );
        initialLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        SnackBarUtils.showError(
          context,
          message: 'Failed to get current location: $e',
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _FullScreenMapDialog(
          currentLocation: initialLocation,
          siteName: _siteNameController.text.trim().isNotEmpty
              ? _siteNameController.text.trim()
              : 'New Site',
          onLocationSelected: (LatLng location, String address) {
            // Update the current location and address
            setState(() {
              _selectedLocation = location;
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
            _selectedLocation = LatLng(lat, lng);
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

  Future<void> _getCurrentLocation() async {
    try {
      // Dismiss keyboard when getting current location
      _dismissKeyboard();
      
      setState(() {
        _isLoading = true;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        SnackBarUtils.showError(
          context,
          message: 'Location services are disabled. Please enable location services.',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

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

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
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
               _latitudeController.text = position.latitude.toStringAsFixed(6);
               _longitudeController.text = position.longitude.toStringAsFixed(6);
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
                
                setState(() {
                  _addressController.text = address;
                });
              }
            } catch (e) {
              print('Error getting address: $e');
            }
          },
        ),
      );
    }
  }

  Future<void> _createSite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Only validate end date if both start date and end date are selected
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      SnackBarUtils.showError(context, message: 'End date cannot be before start date');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        SnackBarUtils.showError(context, message: 'Authentication token not found');
        return;
      }

      final response = await ApiService.createSite(
        apiToken: apiToken,
        siteName: _siteNameController.text.trim(),
        clientName: _clientNameController.text.trim(),
        architectName: _architectNameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        images: _selectedImages,
        latitude: double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        longitude: double.tryParse(_longitudeController.text.trim()) ?? 0.0,
        address: _addressController.text.trim(),
        minRange: int.tryParse(_minRangeController.text.trim()) ?? 500,
        maxRange: int.tryParse(_maxRangeController.text.trim()) ?? 500,
      );

      if (response.isSuccess) {
        SnackBarUtils.showSuccess(context, message: 'Site created successfully');
        NavigationUtils.pop(context);
      } else {
        SnackBarUtils.showError(context, message: response.message);
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Failed to create site: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Site',
        showDrawer: false,
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping anywhere on the screen
          _dismissKeyboard();
        },
        child: DismissKeyboard(
          child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site Name
                CustomTextField(
                  controller: _siteNameController,
                  label: 'Site Name',
                  prefixIcon: Icon(Icons.business),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter site name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),

                // Client Name
                CustomTextField(
                  controller: _clientNameController,
                  label: 'Client Name',
                  prefixIcon: Icon(Icons.person),
                  // validator: (value) {
                  //   if (value == null || value.trim().isEmpty) {
                  //     return 'Please enter client name';
                  //   }
                  //   return null;
                  // },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),

                // Architect Name
                CustomTextField(
                  controller: _architectNameController,
                  label: 'Architect Name',
                  prefixIcon: Icon(Icons.architecture),
                  // validator: (value) {
                  //   if (value == null || value.trim().isEmpty) {
                  //     return 'Please enter architect name';
                  //   }
                  //   return null;
                  // },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),

                // Start Date
                CustomDatePickerField(
                  controller: TextEditingController(
                    text: _startDate != null 
                      ? '${_startDate!.day.toString().padLeft(2, '0')}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.year}'
                      : ''
                  ),
                  label: 'Start Date',
                  onTap: _selectStartDate,
                  // validator: (value) {
                  //   if (_startDate == null) {
                  //     return 'Please select start date';
                  //   }
                  //   return null;
                  // },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),

                // End Date
                CustomDatePickerField(
                  controller: TextEditingController(
                    text: _endDate != null 
                      ? '${_endDate!.day.toString().padLeft(2, '0')}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.year}'
                      : ''
                  ),
                  label: 'End Date',
                  onTap: _selectEndDate,
                  // validator: (value) {
                  //   if (_endDate == null) {
                  //     return 'Please select end date';
                  //   }
                  //   return null;
                  // },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                
                // Search Field
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
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                      ),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
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
                 
                 // Full Screen Map Button
                 Row(
                   children: [
                     Expanded(
                       child: ElevatedButton.icon(
                         onPressed: _showFullScreenMap,
                         icon: Icon(Icons.fullscreen, size: 18),
                         label: Text('View Full Screen Map'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Theme.of(context).colorScheme.primary,
                           foregroundColor: Theme.of(context).colorScheme.onPrimary,
                           padding: EdgeInsets.symmetric(
                             vertical: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                           ),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(
                               ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                             ),
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
                 SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                 
                 Container(
                  height: ResponsiveUtils.responsiveFontSize(context, mobile: 200, tablet: 250, desktop: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    border: Border.all(color: AppColors.borderColor, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation ?? const LatLng(20.5937, 78.9629), // India center
                            zoom: 5.0,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          onTap: (LatLng position) async {
                            // Dismiss keyboard when tapping on map
                            _dismissKeyboard();
                            
                            setState(() {
                              _selectedLocation = position;
                              _updateMarkers();
                            });

                            // Update coordinates
                            _latitudeController.text = position.latitude.toStringAsFixed(6);
                            _longitudeController.text = position.longitude.toStringAsFixed(6);

                            // Get address from coordinates
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
                              print('Error getting address: $e');
                            }
                          },
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false, // Disable default zoom controls
                          mapToolbarEnabled: false,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                          },
                        ),
                        
                        // Custom zoom controls
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
                              // Current Location Button
                              Container(
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
                                    onTap: _getCurrentLocation,
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        ResponsiveUtils.responsiveSpacing(
                                          context,
                                          mobile: 8,
                                          tablet: 10,
                                          desktop: 12,
                                        ),
                                      ),
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
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        ResponsiveUtils.responsiveSpacing(
                                          context,
                                          mobile: 8,
                                          tablet: 10,
                                          desktop: 12,
                                        ),
                                      ),
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
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        ResponsiveUtils.responsiveSpacing(
                                          context,
                                          mobile: 8,
                                          tablet: 10,
                                          desktop: 12,
                                        ),
                                      ),
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _latitudeController,
                        label: 'Latitude',
                        prefixIcon: Icon(Icons.gps_fixed),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter latitude';
                          }
                          final lat = double.tryParse(value);
                          if (lat == null || lat < -90 || lat > 90) {
                            return 'Invalid latitude';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                    Expanded(
                      child: CustomTextField(
                        controller: _longitudeController,
                        label: 'Longitude',
                        prefixIcon: Icon(Icons.gps_fixed),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter longitude';
                          }
                          final lng = double.tryParse(value);
                          if (lng == null || lng < -180 || lng > 180) {
                            return 'Invalid longitude';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _minRangeController,
                        label: 'Min Range',
                        prefixIcon: Icon(Icons.trending_down),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        // No validation needed - any value is allowed, empty defaults to 500
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                    Expanded(
                      child: CustomTextField(
                        controller: _maxRangeController,
                        label: 'Max Range',
                        prefixIcon: Icon(Icons.trending_up),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        // No validation needed - any value is allowed, empty defaults to 500
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                Text(
                  'Site Images',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),

                // Add Images Button
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                      border: Border.all(color: AppColors.borderColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: Theme.of(context).colorScheme.primary,
                          size: ResponsiveUtils.responsiveFontSize(context, mobile: 32, tablet: 36, desktop: 40),
                        ),
                        SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                        Text(
                          'Add Images',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),

                // Selected Images Grid
                if (_selectedImages.isNotEmpty) ...[
                  Text(
                    'Selected Images (${_selectedImages.length})',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                      mainAxisSpacing: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                              border: Border.all(color: AppColors.borderColor, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                              child: Image.file(
                                File(_selectedImages[index]),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Theme.of(context).colorScheme.onError,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                ],

                // Create Site Button
                CustomButton(
                  text: _isLoading ? 'Creating Site...' : 'Create Site',
                  onPressed: _isLoading ? null : _createSite,
                  isLoading: _isLoading,
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _FullScreenMapDialog extends StatefulWidget {
  final LatLng? currentLocation;
  final String siteName;
  final Function(LatLng location, String address) onLocationSelected;

  const _FullScreenMapDialog({
    this.currentLocation,
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
    
    // If no current location provided, get user's current location
    if (widget.currentLocation == null) {
      _getCurrentLocation();
    }
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
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _updateMarkers();
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
                target: widget.currentLocation ?? const LatLng(0.0, 0.0),
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
