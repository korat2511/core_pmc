import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ActionByPicker extends StatefulWidget {
  final List<String> selectedNames;
  final List<CategoryModel> categories;
  final Function(List<String>) onChanged;
  final String hintText;
  final bool enabled;
  final int siteId;
  final int? discussionId; // Add discussion ID parameter

  const ActionByPicker({
    super.key,
    required this.selectedNames,
    required this.categories,
    required this.onChanged,
    required this.siteId,
    this.discussionId, // Make it optional for backward compatibility
    this.hintText = 'Action by',
    this.enabled = true,
  });

  @override
  State<ActionByPicker> createState() => _ActionByPickerState();
}

class _ActionByPickerState extends State<ActionByPicker> {
  @override
  void dispose() {
    super.dispose();
  }



  void _removeName(String name) {
    final updatedNames = List<String>.from(widget.selectedNames);
    updatedNames.remove(name);
    setState(() {
      widget.selectedNames.clear();
      widget.selectedNames.addAll(updatedNames);
    });
    widget.onChanged(updatedNames);
  }

  Future<void> _showActionBySelectionModal() async {
    // Dismiss keyboard before opening modal
    FocusScope.of(context).unfocus();
    
    // Additional aggressive keyboard dismissal
    await Future.delayed(Duration(milliseconds: 50));
    FocusScope.of(context).unfocus();
    
    // Create a temporary list for the modal
    List<String> tempSelectedNames = List.from(widget.selectedNames);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _ActionByModalContent(
          selectedNames: tempSelectedNames,
          categories: widget.categories,
          siteId: widget.siteId,
          onChanged: (names) {
            setModalState(() {
              tempSelectedNames.clear();
              tempSelectedNames.addAll(names);
            });
          },
          onSave: () {
            setState(() {
              widget.selectedNames.clear();
              widget.selectedNames.addAll(tempSelectedNames);
            });
            widget.onChanged(List.from(widget.selectedNames));
            Navigator.pop(context);
            // Ensure keyboard stays dismissed after modal closes
            Future.delayed(Duration(milliseconds: 100), () {
              FocusScope.of(context).unfocus();
            });
          },
          onCancel: () {
            Navigator.pop(context);
            // Ensure keyboard stays dismissed after modal closes
            Future.delayed(Duration(milliseconds: 100), () {
              FocusScope.of(context).unfocus();
            });
          },
        ),
      ),
    );
    
    // Additional safety: ensure keyboard is dismissed after modal is closed
    await Future.delayed(Duration(milliseconds: 100));
    FocusScope.of(context).unfocus();
    
    // Extra safety with another delay
    await Future.delayed(Duration(milliseconds: 200));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selection button
        GestureDetector(
          onTap: widget.enabled ? _showActionBySelectionModal : null,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedNames.isEmpty ? widget.hintText : '${widget.selectedNames.length} selected',
                  style: AppTypography.bodyMedium.copyWith(
                    color: widget.selectedNames.isEmpty 
                        ? Theme.of(context).colorScheme.onSurfaceVariant 
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        
        // Selected names chips
        if (widget.selectedNames.isNotEmpty) ...[
          SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.selectedNames.map((name) => Chip(
              label: Text(name),
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () => _removeName(name),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],
      ],
    );
  }
}

class _ActionByModalContent extends StatefulWidget {
  final List<String> selectedNames;
  final List<CategoryModel> categories;
  final int siteId;
  final Function(List<String>) onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ActionByModalContent({
    required this.selectedNames,
    required this.categories,
    required this.siteId,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ActionByModalContent> createState() => _ActionByModalContentState();
}

class _ActionByModalContentState extends State<_ActionByModalContent> {
  final TextEditingController _otherTextController = TextEditingController();
  final FocusNode _otherTextFocusNode = FocusNode();
  
  List<String> _vendors = [];
  bool _isLoadingVendors = false;
  String? _selectedParentOption;
  bool _showOtherTextField = false;

  final List<String> _parentOptions = [
    'PMC',
    'Client', 
    'Architect',
    'Agency',
    'Vendor',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _otherTextController.dispose();
    _otherTextFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoadingVendors = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getSiteVendors(
          siteId: widget.siteId,
        );
        
        if (response != null && response.status == 'success') {
          setState(() {
            _vendors = response.data.map((v) => v.name).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading vendors: $e');
    } finally {
      setState(() {
        _isLoadingVendors = false;
      });
    }
  }

  void _selectParentOption(String option) {
    setState(() {
      // If clicking the same parent option that's already selected, close the sub-list
      if (_selectedParentOption == option) {
        _selectedParentOption = null;
        _showOtherTextField = false;
        return;
      }
      
      _selectedParentOption = option;
      _showOtherTextField = false;
      
      if (option == 'Other') {
        _showOtherTextField = true;
        // Don't auto-focus the text field to prevent keyboard opening
        // User can manually tap to focus if needed
      } else {
        // For direct selections (PMC, Client, Architect, Structure), add them immediately
        if (!['Agency', 'Vendor'].contains(option)) {
          if (!widget.selectedNames.contains(option)) {
            widget.onChanged([...widget.selectedNames, option]);
          } else {
            // If already selected, remove it
            widget.onChanged(widget.selectedNames.where((name) => name != option).toList());
          }
          _selectedParentOption = null; // Reset selection
          FocusScope.of(context).unfocus(); // Dismiss keyboard
        }
      }
    });
  }

  void _selectSubOption(String option) {
    if (_selectedParentOption != null) {
      String displayName = '$_selectedParentOption - $option';
      
      if (!widget.selectedNames.contains(displayName)) {
        widget.onChanged([...widget.selectedNames, displayName]);
      } else {
        // If already selected, remove it
        widget.onChanged(widget.selectedNames.where((name) => name != displayName).toList());
      }
      
      // Don't reset parent selection - keep the sub-list open for multiple selections
      // Dismiss keyboard after selection
      FocusScope.of(context).unfocus();
    }
  }

  void _selectOtherOption() {
    final text = _otherTextController.text.trim();
    if (text.isNotEmpty) {
      String displayName = 'Other - $text';
      
      if (!widget.selectedNames.contains(displayName)) {
        widget.onChanged([...widget.selectedNames, displayName]);
      }
      
      _otherTextController.clear();
      setState(() {
        _selectedParentOption = null;
        _showOtherTextField = false;
      });
      FocusScope.of(context).unfocus(); // Dismiss keyboard after adding other option
    }
  }


  List<String> _getSubOptions() {
    switch (_selectedParentOption) {
      case 'Agency':
        return widget.categories.map((c) => c.name).toList();
      case 'Vendor':
        return _vendors;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dismiss keyboard when modal content builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
    
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: DraggableScrollableSheet(

        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Select Action By',
                        style: AppTypography.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: widget.onCancel,
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Parent options
                      ..._parentOptions.map((option) => _buildOptionCard(
                        option,
                        widget.selectedNames.contains(option) || 
                        widget.selectedNames.any((name) => name.startsWith('$option -')),
                        onTap: () => _selectParentOption(option),
                        isActive: _selectedParentOption == option,
                      )),

                      // Sub options for Agency/Vendor
                      if (_selectedParentOption == 'Agency' || _selectedParentOption == 'Vendor') ...[
                        SizedBox(height: 16),
                        Text(
                          'Select ${_selectedParentOption}:',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (_isLoadingVendors && _selectedParentOption == 'Vendor')
                          Center(child: CircularProgressIndicator())
                        else
                          ..._getSubOptions().map((subOption) => _buildOptionCard(
                            subOption,
                            widget.selectedNames.contains('$_selectedParentOption - $subOption'),
                            onTap: () => _selectSubOption(subOption),
                            isSubOption: true,
                          )),
                      ],

                      // Other text field
                      if (_showOtherTextField) ...[
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _otherTextController,
                                focusNode: _otherTextFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'Enter custom value',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onSubmitted: (_) => _selectOtherOption(),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _selectOtherOption,
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      ],



                      SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),

                // Action buttons
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onCancel,
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.selectedNames.isEmpty ? null : widget.onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            widget.selectedNames.isEmpty 
                                ? 'Select' 
                                : 'Select (${widget.selectedNames.length})',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard(
    String option,
    bool isSelected, {
    required VoidCallback onTap,
    bool isSubOption = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : isActive
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                    : AppColors.borderColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isSubOption) ...[
              SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                option,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}