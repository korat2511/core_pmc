import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/site_vendor_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class SiteVendorScreen extends StatefulWidget {
  final SiteModel site;

  const SiteVendorScreen({
    super.key,
    required this.site,
  });

  @override
  State<SiteVendorScreen> createState() => _SiteVendorScreenState();
}

class _SiteVendorScreenState extends State<SiteVendorScreen> {
  List<SiteVendorModel> _vendors = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getSiteVendors(siteId: widget.site.id);
      
      if (response != null && response.status == 'success') {
        setState(() {
          _vendors = response.data;
        });
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Failed to load vendors',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error loading vendors: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshVendors() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadVendors();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _showAddVendorDialog() {
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
        child: _VendorDialog(
          site: widget.site,
          vendor: null,
          onSuccess: () {
            Navigator.of(context).pop();
            _loadVendors();
          },
        ),
      ),
    );
  }

  void _showEditVendorDialog(SiteVendorModel vendor) {
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
        child: _VendorDialog(
          site: widget.site,
          vendor: vendor,
          onSuccess: () {
            Navigator.of(context).pop();
            _loadVendors();
          },
        ),
      ),
    );
  }

  Future<void> _deleteVendor(SiteVendorModel vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Vendor'),
        content: Text('Are you sure you want to delete ${vendor.name}?'),
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
        final success = await ApiService.deleteSiteVendor(vendorId: vendor.id);
        
        if (success) {
          SnackBarUtils.showSuccess(
            context,
            message: 'Vendor deleted successfully',
          );
          _loadVendors();
        } else {
          SnackBarUtils.showError(
            context,
            message: 'Failed to delete vendor',
          );
        }
      } catch (e) {
        SnackBarUtils.showError(
          context,
          message: 'Error deleting vendor: ${e.toString()}',
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
        title: 'Site Vendors',
        showDrawer: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshVendors,
              child: _vendors.isEmpty
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
                            'No vendors found',
                            style: AppTypography.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first vendor to get started',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: ResponsiveUtils.responsivePadding(context),
                      itemCount: _vendors.length,
                      itemBuilder: (context, index) {
                        final vendor = _vendors[index];
                        return _buildVendorCard(vendor);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVendorDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVendorCard(SiteVendorModel vendor) {
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
                        vendor.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                                             Text(
                         vendor.gstNo ?? 'No GST Number',
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
                        _showEditVendorDialog(vendor);
                        break;
                      case 'delete':
                        _deleteVendor(vendor);
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
                    vendor.mobile,
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
                    vendor.email,
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

class _VendorDialog extends StatefulWidget {
  final SiteModel site;
  final SiteVendorModel? vendor;
  final VoidCallback onSuccess;

  const _VendorDialog({
    required this.site,
    this.vendor,
    required this.onSuccess,
  });

  @override
  State<_VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends State<_VendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  
  bool _isLoading = false;
  bool _isDialogClosing = false;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _nameController.text = widget.vendor!.name;
      _mobileController.text = widget.vendor!.mobile;
      _emailController.text = widget.vendor!.email;
      _gstController.text = widget.vendor!.gstNo ?? '';
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



  Future<void> _selectFromContacts() async {
    try {
      // Check if widget is still mounted and dialog is not closing
      if (!mounted || _isDialogClosing) return;

      // Request permission
      if (!await FlutterContacts.requestPermission()) {
        if (!mounted) return;
        SnackBarUtils.showError(
          context,
          message: 'Permission denied to access contacts',
        );
        return;
      }

      // Get all contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      if (contacts.isEmpty) {
        SnackBarUtils.showInfo(
          context,
          message: 'No contacts found',
        );
        return;
      }

      // Show contact selection dialog
      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Contact'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final name = contact.displayName;
                final phones = contact.phones.map((p) => p.number).toList();
                final emails = contact.emails.map((e) => e.address).toList();
                
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name.isNotEmpty ? name : 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (phones.isNotEmpty) 
                        Text('📞 ${phones.first}'),
                      if (emails.isNotEmpty) 
                        Text('📧 ${emails.first}'),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(contact),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      );

      // Check if widget is still mounted after dialog
      if (!mounted) return;

      if (selectedContact != null) {
        setState(() {
          _nameController.text = selectedContact.displayName;
          
          // Set first phone number
          if (selectedContact.phones.isNotEmpty) {
            _mobileController.text = selectedContact.phones.first.number;
          }
          
          // Set first email if available
          if (selectedContact.emails.isNotEmpty) {
            _emailController.text = selectedContact.emails.first.address;
          }
        });
      }
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;
      
      SnackBarUtils.showError(
        context,
        message: 'Error accessing contacts: ${e.toString()}',
      );
    }
  }

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = widget.vendor == null
          ? await ApiService.saveSiteVendor(
              siteId: widget.site.id,
              name: _nameController.text.trim(),
              mobile: _mobileController.text.trim(),
              email: _emailController.text.trim().isEmpty ? '' : _emailController.text.trim(),
              gstNo: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
            )
          : await ApiService.updateSiteVendor(
              vendorId: widget.vendor!.id,
              siteId: widget.site.id,
              name: _nameController.text.trim(),
              mobile: _mobileController.text.trim(),
              email: _emailController.text.trim().isEmpty ? '' : _emailController.text.trim(),
              gstNo: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
            );

      if (result != null) {
        SnackBarUtils.showSuccess(
          context,
          message: widget.vendor == null 
              ? 'Vendor added successfully' 
              : 'Vendor updated successfully',
        );
        widget.onSuccess();
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Failed to ${widget.vendor == null ? 'add' : 'update'} vendor',
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
                    widget.vendor == null ? 'Add Vendor' : 'Edit Vendor',
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // GST Number Field
                    CustomTextField(
                      controller: _gstController,
                      label: 'GST Number',
                      hintText: 'Enter GST number (optional)',
                      validator: (value) {
                        return null; // GST is optional
                      },
                    ),
                    SizedBox(height: 16),

                    // Select from Contact Button (only for Add mode)
                    if (widget.vendor == null) ...[
                      GestureDetector(
                        onTap: _selectFromContacts,
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
                              Icon(Icons.contacts, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 12),
                              Text(
                                'Select from Contact',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
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
                      hintText: 'Enter vendor name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter vendor name';
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
                            text: widget.vendor == null ? 'Add' : 'Update',
                            onPressed: _isLoading ? null : _saveVendor,
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
          ],
        ),
      ),
    );
  }
}
