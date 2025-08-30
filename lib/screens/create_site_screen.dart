import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/custom_image_picker.dart';
import '../widgets/custom_button.dart';
import '../widgets/dismiss_keyboard.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final String? selectedDate = await DatePickerUtils.pickDate(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
      firstDate: _startDate ?? DateTime.now(),
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

    if (_startDate == null) {
      SnackBarUtils.showError(context, message: 'Please select start date');
      return;
    }

    if (_endDate == null) {
      SnackBarUtils.showError(context, message: 'Please select end date');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
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
      body: DismissKeyboard(
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter client name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),

                // Architect Name
                CustomTextField(
                  controller: _architectNameController,
                  label: 'Architect Name',
                  prefixIcon: Icon(Icons.architecture),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter architect name';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (_startDate == null) {
                      return 'Please select start date';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (_endDate == null) {
                      return 'Please select end date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                Container(
                  height: ResponsiveUtils.responsiveFontSize(context, mobile: 200, tablet: 250, desktop: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    border: Border.all(color: AppColors.borderColor, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation ?? const LatLng(20.5937, 78.9629), // India center
                        zoom: 5.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      onTap: (LatLng position) async {
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
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
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
    );
  }
}
