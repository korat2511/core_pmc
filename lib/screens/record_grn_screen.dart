import 'dart:io';
import 'package:core_pmc/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/image_picker_utils.dart';
import '../models/po_detail_model.dart';
import '../models/site_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_image_picker.dart';

class GrnImageWithDescription {
  final File image;
  final String description;

  GrnImageWithDescription({
    required this.image,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'image': image.path,
      'description': description,
    };
  }
}

class RecordGrnScreen extends StatefulWidget {
  final PODetailModel? poDetail;
  final PendingItem? pendingItem;
  final String? receivedQuantity;
  final List<Map<String, dynamic>>? selectedMaterials;
  final SiteModel? site;

  const RecordGrnScreen({
    super.key,
    this.poDetail,
    this.pendingItem,
    this.receivedQuantity,
    this.selectedMaterials,
    this.site,
  }) : assert(
          (poDetail != null && pendingItem != null && receivedQuantity != null) ||
          (site != null),
          'Either provide PO details or site for GRN creation',
        );

  @override
  State<RecordGrnScreen> createState() => _RecordGrnScreenState();
}

class _RecordGrnScreenState extends State<RecordGrnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _grnIdController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _totalInvoiceAmountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _deliveryChallanController = TextEditingController();
  
  String? _generatedGrnId;
  bool _isLoading = false;
  bool _isGeneratingId = false;
  bool _isCustomGrnId = false;
  bool _showDeliveryChallan = false;
  List<GrnImageWithDescription> _grnImages = [];
  final List<TextEditingController> _imageDescriptionControllers = [];

  @override
  void initState() {
    super.initState();
    _generateAutoGrnId();
    
    // If we have selected materials, populate the form
    if (widget.selectedMaterials != null) {
      _populateFromSelectedMaterials();
    }
  }

  void _populateFromSelectedMaterials() {
    // Pre-fill form with selected materials data
    // This will be used to show the materials in the form
    if (widget.selectedMaterials != null) {
      // Materials were selected - form is ready for GRN creation
    } else {
      // Photo upload flow - no materials needed, user can add photos directly
    }
  }

  @override
  void dispose() {
    _grnIdController.dispose();
    _invoiceNumberController.dispose();
    _totalInvoiceAmountController.dispose();
    _remarksController.dispose();
    _deliveryChallanController.dispose();
    for (var controller in _imageDescriptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generateAutoGrnId() async {
    setState(() {
      _isGeneratingId = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        setState(() {
          _isGeneratingId = false;
        });
        return;
      }

      final response = await ApiService.generateOrderId(
        apiToken: user.apiToken,
        type: 'grn',
      );
      
      if (response.status == 1) {
        setState(() {
          _generatedGrnId = response.data?['order_id'] ?? 'GRN000001';
          _grnIdController.text = _generatedGrnId!;
          _isCustomGrnId = false;
        });
      } else {
        setState(() {
          _generatedGrnId = 'GRN000001';
          _grnIdController.text = _generatedGrnId!;
          _isCustomGrnId = false;
        });
      }
    } catch (e) {
      setState(() {
        _generatedGrnId = 'GRN000001';
        _grnIdController.text = _generatedGrnId!;
        _isCustomGrnId = false;
      });
    } finally {
      setState(() {
        _isGeneratingId = false;
      });
    }
  }

  Future<void> _addImages(List<File> selectedImages) async {
    for (File image in selectedImages) {
      final descriptionController = TextEditingController();
      _imageDescriptionControllers.add(descriptionController);
      
      _grnImages.add(
        GrnImageWithDescription(
          image: image,
          description: '',
        ),
      );
    }
    setState(() {});
    
    // Automatically show full-screen viewer for the last added image
    if (selectedImages.isNotEmpty) {
      final lastImageIndex = _grnImages.length - 1;
      _showImageFullScreen(lastImageIndex);
    }
  }

  Future<void> _showImagePicker() async {
    final images = await ImagePickerUtils.pickImages(
      context: context,
      chooseMultiple: true,
      maxImages: 5 - _grnImages.length,
    );
    
    if (images.isNotEmpty) {
      await _addImages(images);
    }
  }

  void _removeImage(int index) {
    if (index < _grnImages.length && index < _imageDescriptionControllers.length) {
      _imageDescriptionControllers[index].dispose();
      _imageDescriptionControllers.removeAt(index);
      _grnImages.removeAt(index);
      setState(() {});
    }
  }

  void _showImageFullScreen(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageFullScreenViewer(
          images: _grnImages,
          initialIndex: index,
          onDescriptionUpdated: (int imageIndex, String description) {
            print('Updating description for image $imageIndex: $description');
            setState(() {
              _grnImages[imageIndex] = GrnImageWithDescription(
                image: _grnImages[imageIndex].image,
        description: description,
              );
              _imageDescriptionControllers[imageIndex].text = description;
            });
            print('Description updated successfully');
          },
        ),
      ),
    );
  }

  // Show custom GRN ID dialog
  void _showCustomGrnIdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom GRN ID'),
        content: Text(
          'Do you want to use a custom GRN ID instead of the auto-generated one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          CustomButton(
            text: 'Yes, Use Custom ID',
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isCustomGrnId = true;
                // _grnIdController.clear();
              });
            },
            backgroundColor: AppColors.primaryColor,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // Regenerate GRN ID
  void _regenerateGrnId() {
    setState(() {
      _isCustomGrnId = false;
    });
    _generateAutoGrnId();
  }



  Future<void> _saveGrn() async {
    if (!_formKey.currentState!.validate()) return;

    // For photo upload flow, ensure at least images are provided
    if (widget.selectedMaterials == null && 
        widget.pendingItem == null && 
        _grnImages.isEmpty) {
      SnackBarUtils.showWarning(context, message: 'Please add at least one image for GRN creation');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare material data for API
      List<Map<String, dynamic>> grnMaterials;
      
      if (widget.selectedMaterials != null) {
        // Material selection flow: Use selected materials
        grnMaterials = widget.selectedMaterials!.map((material) => {
          'material_id': material['material_id'],
          'quantity': material['quantity'],
        }).toList();
      } else if (widget.pendingItem != null && widget.receivedQuantity != null) {
        // PO flow: Use PO pending item
        grnMaterials = [
          {
            'material_id': widget.pendingItem!.materialId,
            'quantity': int.parse(widget.receivedQuantity!),
          }
        ];
      } else {
        // Photo upload flow: No materials (empty list)
        grnMaterials = [];
      }

      // Prepare image data for API - only if images exist
      List<Map<String, dynamic>>? grnDocuments;
      if (_grnImages.isNotEmpty) {
        grnDocuments = _grnImages.map((img) => {
          'file': img.image,
          'description': img.description.isNotEmpty ? img.description : '',
        }).toList();
      }

      final response = await ApiService.saveGrn(
        grnDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        grnNumber: _grnIdController.text,
        deliveryChallanNumber: _showDeliveryChallan ? _deliveryChallanController.text : 'INV000001',
        poId: widget.poDetail?.id ?? 0, // Use 0 for direct GRN creation
        vendorId: widget.poDetail?.vendorId ?? 1, // Default vendor for direct GRN
        siteId: widget.poDetail?.siteId ?? widget.site!.id,
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        grnMaterials: grnMaterials,
        grnDocuments: _grnImages.isNotEmpty ? grnDocuments : null, // Only send if images exist
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(context, message: "GRN saved successfully!");
        
        // Navigate back
        Navigator.of(context).pop(true);
      } else {
        // Show the actual error message from the API
        SnackBarUtils.showError(
          context, 
          message: response?.message ?? "Failed to save GRN"
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: "Error: ${e.toString()}");

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
        title: 'GRN',
        showDrawer: false,
        showBackButton: true,
      ),


      body: GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GRN ID Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _grnIdController,
                        decoration: InputDecoration(
                              hintText: _isGeneratingId
                                  ? 'Generating...'
                                  : 'Enter GRN ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                            readOnly: !_isCustomGrnId && !_isGeneratingId,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter GRN ID';
                          }
                          return null;
                        },
                      ),
                    ),
                        if (!_isCustomGrnId && !_isGeneratingId) ...[
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: _showCustomGrnIdDialog,
                            icon: Icon(Icons.edit, color: AppColors.primaryColor),
                            tooltip: 'Use Custom ID',
                          ),
                        ],
                        if (_isCustomGrnId) ...[
                    SizedBox(width: 8),
                    IconButton(
                            onPressed: _regenerateGrnId,
                            icon: Icon(
                              Icons.refresh,
                              color: AppColors.primaryColor,
                            ),
                            tooltip: 'Regenerate Auto ID',
                          ),
                        ],
                      ],
                    ),
                    if (!_isCustomGrnId && !_isGeneratingId)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Auto-generated ID. Tap edit icon to use custom ID.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_isCustomGrnId)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Custom ID mode. Tap refresh icon to use auto-generated ID.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_isGeneratingId)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generating GRN ID...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),


                // Show selected images with remove functionality
                if (_grnImages.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._grnImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final imageData = entry.value;
                          return Container(
                            margin: EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _showImageFullScreen(index),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        imageData.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Icon(Icons.broken_image, color: Colors.grey[400]),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        // Add Image button
                        if (_grnImages.length < 5)
                          GestureDetector(
                            onTap: () => _showImagePicker(),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primaryColor),
                                color: Colors.white,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    color: AppColors.primaryColor,
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_grnImages.length}/5 images selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ] else ...[
                  // Show image picker when no images are selected
                  CustomImagePicker(
                    selectedImages: [],
                    onImagesSelected: _addImages,
                    chooseMultiple: true,
                    maxImages: 5,
                    title: null,
                    subtitle: null,
                  ),
                ],

                SizedBox(height: 16),

                // Invoice Number Field
                Text(
                  'Invoice Number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                TextFormField(
                  controller: _invoiceNumberController,
                  decoration: InputDecoration(
                    hintText: 'Enter here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                SizedBox(height: 16),

                // Total Invoice Amount Field
                Text(
                  'Total Invoice Amount (Inclusive of GST)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                TextFormField(
                  controller: _totalInvoiceAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                SizedBox(height: 16),

                // Remarks Field
                Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add remark',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                SizedBox(height: 16),

                // Delivery Challan Number
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDeliveryChallan = !_showDeliveryChallan;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delivery Challan Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showDeliveryChallan) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _deliveryChallanController,
                    decoration: InputDecoration(
                      hintText: 'Enter delivery challan number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],


                SizedBox(height: 32),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Done',
                    onPressed: _saveGrn,
                    isLoading: _isLoading,
                      backgroundColor: AppColors.primaryColor,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageFullScreenViewer extends StatefulWidget {
  final List<GrnImageWithDescription> images;
  final int initialIndex;
  final Function(int, String) onDescriptionUpdated;

  const _ImageFullScreenViewer({
    required this.images,
    required this.initialIndex,
    required this.onDescriptionUpdated,
  });

  @override
  State<_ImageFullScreenViewer> createState() => _ImageFullScreenViewerState();
}

class _ImageFullScreenViewerState extends State<_ImageFullScreenViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _descriptionController.text = widget.images[_currentIndex].description;
    
  }

  @override
  void dispose() {
    // Save current description before disposing
    widget.onDescriptionUpdated(_currentIndex, _descriptionController.text);
    _pageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Save current description before switching
    if (_currentIndex != index) {
      widget.onDescriptionUpdated(_currentIndex, _descriptionController.text);
    }
    
    setState(() {
      _currentIndex = index;
      _descriptionController.text = widget.images[_currentIndex].description;
    });
  }

  void _saveDescription() {
    print('Saving description for image $_currentIndex: ${_descriptionController.text}');
    widget.onDescriptionUpdated(_currentIndex, _descriptionController.text);
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: '${_currentIndex + 1} of ${widget.images.length}',
        showDrawer: false,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // Image viewer
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  child: Image.file(
                    widget.images[index].image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // Description overlay - always visible
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add a description for this image (optional)',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Enter description',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 3,
                      autofocus: true,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Save',
                            onPressed: _saveDescription,
                            backgroundColor: AppColors.primaryColor,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
