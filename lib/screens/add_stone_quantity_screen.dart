import 'dart:developer';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/theme/app_typography.dart';
import '../models/element_model.dart';
import '../models/site_model.dart';
import '../models/stone_quantity_model.dart';
import '../widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddStoneQuantityScreen extends StatefulWidget {
  final ElementModel element;
  final SiteModel site;

  const AddStoneQuantityScreen({
    Key? key,
    required this.element,
    required this.site,
  }) : super(key: key);

  @override
  State<AddStoneQuantityScreen> createState() => _AddStoneQuantityScreenState();
}

enum MeasurementUnit { feetInches, meters, centimeters }

class _AddStoneQuantityScreenState extends State<AddStoneQuantityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _floorAreaController = TextEditingController();
  final _skirtingLengthController = TextEditingController();
  final _skirtingHeightController = TextEditingController();
  final _skirtingSubtractLengthController = TextEditingController();
  final _counterTopAdditionalController = TextEditingController();
  final _wallAreaController = TextEditingController();
  final _locationController = TextEditingController();
  final _stoneController = TextEditingController();

  List<StoneModel> _stones = [];
  List<LocationModel> _locations = [];
  StoneModel? _selectedStone;
  LocationModel? _selectedLocation;
  bool _isLoading = false;
  bool _isSubmitting = false;
  MeasurementUnit _selectedUnit = MeasurementUnit.feetInches;

  // Calculated values
  double _skirtingArea = 0.0;
  double _totalCounterSkirtingWall = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateInputFormats();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _floorAreaController.dispose();
    _skirtingLengthController.dispose();
    _skirtingHeightController.dispose();
    _skirtingSubtractLengthController.dispose();
    _counterTopAdditionalController.dispose();
    _wallAreaController.dispose();
    _locationController.dispose();
    _stoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadLocations(),
        _loadStones(),
      ]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocations() async {
    final token = await AuthService.currentToken;
    if (token != null) {
      final response = await ApiService.getSiteLocationList(
        apiToken: token,
        siteId: widget.site.id,
      );

  log("Response == ${response}");


      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _locations = data.map((json) => LocationModel.fromJson(json)).toList();
        });
      }else{
        log("Found issue");
      }
    }
  }

  Future<void> _loadStones() async {
    final token = await AuthService.currentToken;
    if (token != null) {
      final response = await ApiService.getStoneList(apiToken: token);

      if (response != null && response['status'] == 1) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _stones = data.map((json) => StoneModel.fromJson(json)).toList();
        });
      }
    }
  }

  void _calculateSkirtingArea() {
    double length, height, subtractLength;
    
    switch (_selectedUnit) {
      case MeasurementUnit.feetInches:
        length = _parseFeetInches(_skirtingLengthController.text);
        height = _parseFeetInches(_skirtingHeightController.text);
        subtractLength = _parseFeetInches(_skirtingSubtractLengthController.text);
        break;
      case MeasurementUnit.meters:
        length = double.tryParse(_skirtingLengthController.text) ?? 0.0;
        height = double.tryParse(_skirtingHeightController.text) ?? 0.0;
        subtractLength = double.tryParse(_skirtingSubtractLengthController.text) ?? 0.0;
        break;
      case MeasurementUnit.centimeters:
        length = (double.tryParse(_skirtingLengthController.text) ?? 0.0) / 100.0; // Convert cm to m
        height = (double.tryParse(_skirtingHeightController.text) ?? 0.0) / 100.0;
        subtractLength = (double.tryParse(_skirtingSubtractLengthController.text) ?? 0.0) / 100.0;
        break;
    }
    
    final netLength = length - subtractLength;
    final area = netLength * height;
    
    print('Calculating skirting area:');
    print('  Length: $length');
    print('  Height: $height');
    print('  Subtract Length: $subtractLength');
    print('  Net Length: $netLength');
    print('  Skirting Area: $area');
    
    setState(() {
      _skirtingArea = area;
    });
    
    _calculateTotals();
  }

  void _calculateTotals() {
    final floorArea = double.tryParse(_floorAreaController.text) ?? 0.0;
    final counterTopAdditional = double.tryParse(_counterTopAdditionalController.text) ?? 0.0;
    final wallArea = double.tryParse(_wallAreaController.text) ?? 0.0;

    final totalCounterSkirtingWall = _skirtingArea + counterTopAdditional + wallArea;
    final total = floorArea + totalCounterSkirtingWall;

    print('Calculating totals:');
    print('  Floor Area: $floorArea');
    print('  Skirting Area: $_skirtingArea');
    print('  Counter Top Additional: $counterTopAdditional');
    print('  Wall Area: $wallArea');
    print('  Total Counter/Skirting/Wall: $totalCounterSkirtingWall');
    print('  TOTAL: $total');

    setState(() {
      _totalCounterSkirtingWall = totalCounterSkirtingWall;
      _total = total;
    });
  }

  double _parseFeetInches(String value) {
    if (value.isEmpty) return 0.0;
    
    try {
      // Handle format like "10'-6\""
      if (value.contains("'-") && value.contains('"')) {
        final parts = value.split("'-");
        if (parts.length == 2) {
          final feet = int.parse(parts[0]);
          final inchesStr = parts[1].replaceAll('"', '');
          final inches = int.parse(inchesStr);
          return feet + (inches / 12.0);
        }
      }
    } catch (e) {
      print('Error parsing feet/inches: $e');
    }
    return 0.0;
  }

  Future<void> _createNewLocation([String? preFilledName]) async {
    final TextEditingController nameController = TextEditingController(text: preFilledName ?? '');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Location'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Location Name',
            hintText: 'Enter location name (e.g., LIVING ROOM)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await _storeNewLocation(nameController.text.trim());
    }
  }

  Future<void> _showSmartAddLocationDialog(String enteredText) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Not Found'),
        content: Text('Do you want to create "$enteredText" as a new location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _storeNewLocation(enteredText);
    }
  }

  Future<void> _createNewStone([String? preFilledName]) async {
    final TextEditingController nameController = TextEditingController(text: preFilledName ?? '');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Stone'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Stone Name',
            hintText: 'Enter stone name (e.g., GRANITE)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await _storeNewStone(nameController.text.trim());
    }
  }

  Future<void> _showSmartAddStoneDialog(String enteredText) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stone Not Found'),
        content: Text('Do you want to create "$enteredText" as a new stone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _storeNewStone(enteredText);
    }
  }

  Future<void> _storeNewLocation(String name) async {
    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.storeLocation(
          apiToken: token,
          siteId: widget.site.id,
          name: name,
        );

        if (response != null && response['status'] == 1) {
          SnackBarUtils.showSuccess(context, message: 'Location added successfully');
          // Add new location to local list instead of reloading
          final newLocation = LocationModel.fromJson(response['data']);
          setState(() {
            _locations.add(newLocation);
            _selectedLocation = newLocation;
            _locationController.text = newLocation.name;
          });
        } else {
          SnackBarUtils.showError(
            context,
            message: response?['message'] ?? 'Failed to add location',
          );
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error adding location: $e');
    }
  }

  Future<void> _storeNewStone(String name) async {
    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.storeStone(
          apiToken: token,
          name: name,
        );

        if (response != null && response['status'] == 1) {
          SnackBarUtils.showSuccess(context, message: 'Stone added successfully');
          // Add new stone to local list instead of reloading
          final newStone = StoneModel.fromJson(response['data']);
          setState(() {
            _stones.add(newStone);
            _selectedStone = newStone;
            _stoneController.text = newStone.name;
          });
        } else {
          SnackBarUtils.showError(
            context,
            message: response?['message'] ?? 'Failed to add stone',
          );
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error adding stone: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStone == null) {
      SnackBarUtils.showError(context, message: 'Please select a stone');
      return;
    }
    if (_selectedLocation == null) {
      SnackBarUtils.showError(context, message: 'Please select a location');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.addStoneQuantity(
          apiToken: token,
          siteId: widget.site.id,
          siteElementId: widget.element.id,
          siteLocationId: _selectedLocation!.id,
          stoneId: _selectedStone!.id,
          code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
          floorArea: double.tryParse(_floorAreaController.text) ?? 0.0,
          skirtingLength: _skirtingLengthController.text,
          skirtingHeight: _skirtingHeightController.text,
          skirtingSubtractLength: _skirtingSubtractLengthController.text,
          skirtingArea: _skirtingArea,
          counterTopAdditional: double.tryParse(_counterTopAdditionalController.text) ?? 0.0,
          wallArea: double.tryParse(_wallAreaController.text) ?? 0.0,
          totalCounterSkirtingWall: _totalCounterSkirtingWall,
          total: _total,
        );

        if (response != null && response['status'] == 1) {
          SnackBarUtils.showSuccess(context, message: 'Stone quantity added successfully');
          Navigator.of(context).pop(true);
        } else {
          SnackBarUtils.showError(
            context,
            message: response?['message'] ?? 'Failed to add stone quantity',
          );
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error adding stone quantity: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close keyboard and suggestion boxes when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Add Stone Quantity - ${widget.element.name}',
          showDrawer: false,
          showBackButton: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Unit Selection
                    _buildSimpleUnitSelector(),
                    
                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSimpleForm(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Submit Button
                    _buildSimpleSubmitButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSimpleUnitSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Unit:', style: AppTypography.bodyMedium),
          SizedBox(width: 8),
          Expanded(
            child: SegmentedButton<MeasurementUnit>(
              segments: [
                ButtonSegment<MeasurementUnit>(
                  value: MeasurementUnit.feetInches,
                  label: Text('Feet/Inches', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<MeasurementUnit>(
                  value: MeasurementUnit.meters,
                  label: Text('Meters', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<MeasurementUnit>(
                  value: MeasurementUnit.centimeters,
                  label: Text('CM', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_selectedUnit},
              onSelectionChanged: (Set<MeasurementUnit> selection) {
                setState(() {
                  _selectedUnit = selection.first;
                  _updateInputFormats();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleForm() {
    return Column(
      children: [
        // Basic Info
        _buildLocationField(),
        SizedBox(height: 8),
        _buildStoneField(),
        SizedBox(height: 8),
        _buildSimpleInputField('Code (Optional)', _codeController, Icons.tag),
        
        SizedBox(height: 12),
        
        // Area Measurements
        _buildSimpleInputField('Floor Area (SQ. FT.)', _floorAreaController, Icons.square_foot),
        SizedBox(height: 8),
        _buildSimpleInputField('Counter Top Additional (SQ. FT.)', _counterTopAdditionalController, Icons.add_box),
        SizedBox(height: 8),
        _buildSimpleInputField('Wall Area (SQ. FT.)', _wallAreaController, Icons.border_outer),
        
        SizedBox(height: 12),
        
        // Skirting Details
        _buildSimpleSkirtingFields(),
        
        SizedBox(height: 12),
        
        // Totals
        _buildSimpleTotals(),
        
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLocationField() {
    return Autocomplete<LocationModel>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _locations;
        }
        return _locations.where((location) =>
            location.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (LocationModel option) => option.name,
      onSelected: (LocationModel selection) {
        setState(() {
          _selectedLocation = selection;
          _locationController.text = selection.name;
        });
        // Close keyboard after selection
        FocusScope.of(context).unfocus();
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(option.name),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: _locationController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Location',
            prefixIcon: Icon(Icons.location_on, size: 20),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, size: 20),
              onPressed: () => _createNewLocation(_locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            // Update the autocomplete controller
            controller.value = TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            );
          },
          onTapOutside: (event) {
            // Check if entered text doesn't match any location
            final enteredText = _locationController.text.trim();
            if (enteredText.isNotEmpty) {
              final isMatch = _locations.any((location) => 
                location.name.toLowerCase() == enteredText.toLowerCase());
              if (!isMatch) {
                _showSmartAddLocationDialog(enteredText);
              }
            }
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  Widget _buildStoneField() {
    return Autocomplete<StoneModel>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _stones;
        }
        return _stones.where((stone) =>
            stone.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (StoneModel option) => option.name,
      onSelected: (StoneModel selection) {
        setState(() {
          _selectedStone = selection;
          _stoneController.text = selection.name;
        });
        // Close keyboard after selection
        FocusScope.of(context).unfocus();
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(option.name),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: _stoneController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Stone',
            prefixIcon: Icon(Icons.category, size: 20),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, size: 20),
              onPressed: () => _createNewStone(_stoneController.text.trim().isNotEmpty ? _stoneController.text.trim() : null),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            // Update the autocomplete controller
            controller.value = TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            );
          },
          onTapOutside: (event) {
            // Check if entered text doesn't match any stone
            final enteredText = _stoneController.text.trim();
            if (enteredText.isNotEmpty) {
              final isMatch = _stones.any((stone) => 
                stone.name.toLowerCase() == enteredText.toLowerCase());
              if (!isMatch) {
                _showSmartAddStoneDialog(enteredText);
              }
            }
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  Widget _buildSimpleInputField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) {
        _calculateTotals();
      },
    );
  }

  Widget _buildSimpleSkirtingFields() {
    return Column(
      children: [
        _buildSimpleSkirtingField('Skirting Length', _skirtingLengthController, Icons.straighten),
        SizedBox(height: 8),
        _buildSimpleSkirtingField('Skirting Height', _skirtingHeightController, Icons.height),
        SizedBox(height: 8),
        _buildSimpleSkirtingField('Skirting Subtract Length', _skirtingSubtractLengthController, Icons.remove),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue.shade700, size: 16),
              SizedBox(width: 8),
              Text(
                'Skirting Area: ${_skirtingArea.toStringAsFixed(2)} SQ. FT.',
                style: AppTypography.bodySmall.copyWith(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleSkirtingField(String label, TextEditingController controller, IconData icon) {
    String getSuffix() {
      switch (_selectedUnit) {
        case MeasurementUnit.feetInches: return '';
        case MeasurementUnit.meters: return 'm';
        case MeasurementUnit.centimeters: return 'cm';
      }
    }

    return TextFormField(
      controller: controller,
      keyboardType: _selectedUnit == MeasurementUnit.feetInches 
          ? TextInputType.text 
          : TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _selectedUnit == MeasurementUnit.feetInches 
          ? null 
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      readOnly: _selectedUnit == MeasurementUnit.feetInches,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixText: getSuffix(),
        suffixIcon: _selectedUnit == MeasurementUnit.feetInches
            ? IconButton(
                icon: Icon(Icons.edit, size: 16),
                onPressed: () => _showMeasurementPicker(label, controller),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: _selectedUnit != MeasurementUnit.feetInches ? (value) {
        _calculateSkirtingArea();
        _calculateTotals();
      } : null,
    );
  }

  Widget _buildSimpleTotals() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Counter, Skirting & Wall:', style: AppTypography.bodySmall),
              Text('${_totalCounterSkirtingWall.toStringAsFixed(2)} SQ. FT.', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text('${_total.toStringAsFixed(2)} SQ. FT.', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSubmitButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                  SizedBox(width: 12),
                  Text('Adding...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text('Add Stone Quantity'),
                ],
              ),
      ),
    );
  }

  void _updateInputFormats() {
    // Clear and reset input formats based on selected unit
    switch (_selectedUnit) {
      case MeasurementUnit.feetInches:
        _skirtingLengthController.text = "0'-0\"";
        _skirtingHeightController.text = "0'-0\"";
        _skirtingSubtractLengthController.text = "0'-0\"";
        break;
      case MeasurementUnit.meters:
        _skirtingLengthController.text = "0.0";
        _skirtingHeightController.text = "0.0";
        _skirtingSubtractLengthController.text = "0.0";
        break;
      case MeasurementUnit.centimeters:
        _skirtingLengthController.text = "0";
        _skirtingHeightController.text = "0";
        _skirtingSubtractLengthController.text = "0";
        break;
    }
    _calculateSkirtingArea();
    _calculateTotals();
  }

  Future<void> _showMeasurementPicker(String title, TextEditingController controller) async {
    if (_selectedUnit != MeasurementUnit.feetInches) return;
    
    final currentValue = _parseFeetInches(controller.text);
    final feet = currentValue.floor();
    final inches = ((currentValue - feet) * 12).round();
    
    final feetController = TextEditingController(text: feet.toString());
    final inchesController = TextEditingController(text: inches.toString());
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: feetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Feet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: inchesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Inches',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final feet = int.tryParse(feetController.text) ?? 0;
              final inches = int.tryParse(inchesController.text) ?? 0;
              final totalInches = inches;
              if (totalInches >= 12) {
                final newFeet = feet + (totalInches ~/ 12);
                final newInches = totalInches % 12;
                controller.text = "$newFeet'-$newInches\"";
              } else {
                controller.text = "$feet'-$inches\"";
              }
              Navigator.of(context).pop(true);
            },
            child: Text('Set'),
          ),
        ],
      ),
    );

    if (result == true) {
      _calculateSkirtingArea();
      _calculateTotals();
    }
  }
}