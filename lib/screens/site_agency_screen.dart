import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../models/site_model.dart';
import '../models/site_agency_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../core/utils/category_picker_utils.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class SiteAgencyScreen extends StatefulWidget {
  final SiteModel site;

  const SiteAgencyScreen({
    super.key,
    required this.site,
  });

  @override
  State<SiteAgencyScreen> createState() => _SiteAgencyScreenState();
}

class _SiteAgencyScreenState extends State<SiteAgencyScreen> {
  List<SiteAgencyModel> _agencies = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  Future<void> _loadAgencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getSiteAgency(siteId: widget.site.id);

      if (response != null) {
        if (response.status == 'success') {
          setState(() {
            _agencies = response.data;
          });
        } else {
          SnackBarUtils.showError(
            context,
            message: response.message ?? 'Failed to load agencies',
          );
        }
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Failed to load agencies',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error loading agencies: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAgencies() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadAgencies();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _showAddAgencyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AgencyDialog(
          site: widget.site,
          agency: null,
          onSuccess: () {
            Navigator.of(context).pop();
            _loadAgencies();
          },
        ),
      ),
    );
  }

  void _showEditAgencyDialog(SiteAgencyModel agency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AgencyDialog(
          site: widget.site,
          agency: agency,
          onSuccess: () {
            Navigator.of(context).pop();
            _loadAgencies();
          },
        ),
      ),
    );
  }

  Future<void> _deleteAgency(SiteAgencyModel agency) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Agency'),
        content: Text('Are you sure you want to delete ${agency.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await ApiService.deleteSiteAgency(agencyId: agency.id);

        if (result != null) {
          if (result['status'] == 'success') {
            SnackBarUtils.showSuccess(
              context,
              message: result['message'] ?? 'Agency deleted successfully',
            );
            _loadAgencies();
          } else {
            SnackBarUtils.showError(
              context,
              message: result['message'] ?? 'Failed to delete agency',
            );
          }
        } else {
          SnackBarUtils.showError(
            context,
            message: 'Failed to delete agency',
          );
        }
      } catch (e) {
        SnackBarUtils.showError(
          context,
          message: 'Error deleting agency: ${e.toString()}',
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CustomAppBar(
        title: 'Site Agency',
        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshAgencies,
        child: _agencies.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 16),
              Text(
                'No agencies found',
                style: AppTypography.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add your first agency to get started',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: ResponsiveUtils.responsivePadding(context),
          itemCount: _agencies.length,
          itemBuilder: (context, index) {
            final agency = _agencies[index];
            return _buildAgencyCard(agency);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAgencyDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAgencyCard(SiteAgencyModel agency) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agency.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        agency.category?.name ?? 'No Category',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditAgencyDialog(agency);
                        break;
                      case 'delete':
                        _deleteAgency(agency);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Theme.of(context).colorScheme.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                SizedBox(width: 8),
                Text(
                  agency.mobile,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                SizedBox(width: 8),
                Text(
                  agency.email,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgencyDialog extends StatefulWidget {
  final SiteModel site;
  final SiteAgencyModel? agency;
  final VoidCallback onSuccess;

  const _AgencyDialog({
    required this.site,
    this.agency,
    required this.onSuccess,
  });

  @override
  State<_AgencyDialog> createState() => __AgencyDialogState();
}

class __AgencyDialogState extends State<_AgencyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  bool _isDialogClosing = false;

  @override
  void initState() {
    super.initState();
    if (widget.agency != null) {
      _nameController.text = widget.agency!.name;
      _mobileController.text = widget.agency!.mobile;
      _emailController.text = widget.agency!.email;
      // Set the category by default when editing
      _selectedCategory = widget.agency!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _isDialogClosing = true;
    super.dispose();
  }

  Future<void> _selectCategory() async {
    final category = await CategoryPickerUtils.showCategoryPicker(
      context: context,
      siteId: widget.site.id,
      allowedSubIds: [5], // Only show categories with cat_sub_id = 5 for agencies
    );

    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  Future<void> _openNativeContacts() async {
    try {
      // Check if widget is still mounted
      if (!mounted || _isDialogClosing) return;

      // Check current permission status
      bool hasPermission = await FlutterContacts.requestPermission(readonly: true);
      
      // If permission is not granted, return silently
      if (!hasPermission) {
        if (!mounted) return;
        SnackBarUtils.showError(
          context,
          message: 'Contacts permission denied',
        );
        return;
      }

      // Open native contact picker
      final Contact? contact = await FlutterContacts.openExternalPick();
      
      if (contact != null && mounted) {
        _selectContact(contact);
      }
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;
      
      SnackBarUtils.showError(
        context,
        message: 'Error opening contacts: ${e.toString()}',
      );
    }
  }

  void _selectContact(Contact contact) {
    setState(() {
      _nameController.text = contact.displayName;
      
      // Set first phone number
      if (contact.phones.isNotEmpty) {
        _mobileController.text = contact.phones.first.number;
      }
      
      // Set first email if available
      if (contact.emails.isNotEmpty) {
        _emailController.text = contact.emails.first.address;
      }
    });
  }

  Future<void> _saveAgency() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      SnackBarUtils.showError(context, message: 'Please select a category');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = widget.agency == null
          ? await ApiService.saveSiteAgency(
        siteId: widget.site.id,
        categoryId: _selectedCategory!.id,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
      )
          : await ApiService.updateSiteAgency(
        agencyId: widget.agency!.id,
        siteId: widget.site.id,
        categoryId: _selectedCategory!.id,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (result != null) {
        if (result['status'] == 'success') {
          SnackBarUtils.showSuccess(
            context,
            message: result['message'] ?? (widget.agency == null
                ? 'Agency added successfully'
                : 'Agency updated successfully'),
          );
          widget.onSuccess();
        } else {
          SnackBarUtils.showError(
            context,
            message: result['message'] ?? 'Failed to ${widget.agency == null ? 'add' : 'update'} Agency',
          );
        }
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Failed to ${widget.agency == null ? 'add' : 'update'} Agency',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    widget.agency == null ? 'Add Agency' : 'Edit Agency',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isDialogClosing = true;
                      });
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Category Selection
                    GestureDetector(
                      onTap: _selectCategory,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory?.name ?? 'Select Category *',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: _selectedCategory != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Contact Selection Section (only for Add mode)
                    if (widget.agency == null) ...[
                      // Open Native Contacts Button
                      GestureDetector(
                        onTap: _openNativeContacts,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.contacts,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Select from Contacts',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                    ],

                    // Name Field
                    CustomTextField(
                      controller: _nameController,
                      label: 'Name *',
                      hintText: 'Enter agency name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter agency name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Mobile Field
                    CustomTextField(
                      controller: _mobileController,
                      label: 'Mobile *',
                      hintText: 'Enter mobile number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'Enter email address (optional)',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        // Email is optional, but if provided, it must be valid
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isDialogClosing = true;
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: widget.agency == null ? 'Add' : 'Update',
                            onPressed: _isLoading ? null : _saveAgency,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20), // Bottom padding for safe area
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
