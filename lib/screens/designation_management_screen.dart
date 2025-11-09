import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/designation_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/company_notifier.dart';
import '../services/designation_service.dart';
import '../services/permission_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dismiss_keyboard.dart';
import 'designation_permissions_screen.dart';

class DesignationManagementScreen extends StatefulWidget {
  const DesignationManagementScreen({super.key});

  @override
  State<DesignationManagementScreen> createState() =>
      _DesignationManagementScreenState();
}

enum _DesignationAction {
  manageAccess,
  edit,
  toggleStatus,
  delete,
}

class _DesignationManagementScreenState
    extends State<DesignationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  int? _selectedCompanyId;
  bool _isLoading = false;
  bool _isSavingOrder = false;
  String _searchQuery = '';
  StreamSubscription<bool>? _companyChangeSubscription;

  List<DesignationModel> get _designations =>
      DesignationService.designations.where((designation) {
        if (_searchQuery.isEmpty) return true;
        return designation.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<CompanyInfo> get _allowedCompanies =>
      AuthService.currentUser?.allowedCompanies ?? [];

  @override
  void initState() {
    super.initState();
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      if (currentUser.companyId != null) {
        _selectedCompanyId = currentUser.companyId;
      } else if ((currentUser.allowedCompanies?.isNotEmpty ?? false)) {
        _selectedCompanyId = currentUser.allowedCompanies!.first.id;
      }
    }

    _companyChangeSubscription =
        CompanyNotifier.companyChangedStream.listen((_) {
      final updatedUser = AuthService.currentUser;
      if (!mounted) return;

      if (updatedUser?.companyId != null &&
          updatedUser!.companyId != _selectedCompanyId) {
        setState(() {
          _selectedCompanyId = updatedUser.companyId;
        });
        _loadDesignations();
      } else {
        _loadDesignations();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!PermissionService.canManageDesignations()) {
        SnackBarUtils.showError(
          context,
          message:
              'You do not have permission to manage designations for this company.',
        );
      } else if (_selectedCompanyId != null) {
        _loadDesignations();
      }
    });
  }

  @override
  void dispose() {
    _companyChangeSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDesignations() async {
    if (_selectedCompanyId == null) return;

    setState(() {
      _isLoading = true;
    });

    final success = await DesignationService.loadDesignations(
      companyId: _selectedCompanyId!,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
    }
  }

  Future<void> _createDesignation() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null || _selectedCompanyId == null) return;

    final result = await showModalBottomSheet<DesignationFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DesignationFormSheet(
        companyId: _selectedCompanyId!,
      ),
    );

    if (result == null || result.name.trim().isEmpty) return;

    final created = await DesignationService.createDesignation(
      companyId: _selectedCompanyId!,
      name: result.name.trim(),
      order: result.order,
      status: result.status,
    );

    if (!mounted) return;

    if (created != null) {
      setState(() {});
      SnackBarUtils.showSuccess(
        context,
        message: 'Designation "${created.name}" created successfully',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
    }
  }

  Future<void> _editDesignation(DesignationModel designation) async {
    final result = await showModalBottomSheet<DesignationFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DesignationFormSheet(
        designation: designation,
        companyId: designation.companyId,
      ),
    );

    if (result == null) return;

    final updated = await DesignationService.updateDesignation(
      designationId: designation.id,
      name: result.name.trim().isEmpty ? null : result.name.trim(),
      order: result.order,
      status: result.status,
    );

    if (!mounted) return;

    if (updated != null) {
      setState(() {});
      SnackBarUtils.showSuccess(
        context,
        message: 'Designation "${updated.name}" updated successfully',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
    }
  }

  Future<void> _toggleDesignationStatus(DesignationModel designation) async {
    final newStatus = designation.isActive ? 'inactive' : 'active';
    final updated = await DesignationService.updateDesignation(
      designationId: designation.id,
      status: newStatus,
    );

    if (!mounted) return;

    if (updated != null) {
      setState(() {});
      SnackBarUtils.showSuccess(
        context,
        message: 'Designation status updated to ${updated.status}',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
    }
  }

  Future<void> _deleteDesignation(DesignationModel designation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Designation',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          'Are you sure you want to delete "${designation.name}"? '
          'This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success =
        await DesignationService.deleteDesignation(designationId: designation.id);

    if (!mounted) return;

    if (success) {
      setState(() {});
      SnackBarUtils.showSuccess(
        context,
        message: 'Designation "${designation.name}" deleted successfully',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
    }
  }

  Future<void> _reorderDesignations(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final updatedList = List<DesignationModel>.from(_designations);
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);
    final adjustedList = updatedList
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(order: entry.key),
        )
        .toList();

    setState(() {
      _isSavingOrder = true;
    });

    final success = await DesignationService.reorderDesignations(
      companyId: _selectedCompanyId!,
      orderedDesignations: adjustedList,
    );

    if (!mounted) return;

    setState(() {
      _isSavingOrder = false;
    });

    if (success) {
      setState(() {});
      SnackBarUtils.showSuccess(
        context,
        message: 'Designation order updated',
      );
    } else {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
    }
  }

  Future<void> _openDesignationAccess(DesignationModel designation) async {
    await NavigationUtils.push(
      context,
      DesignationPermissionsScreen(designation: designation),
    );
  }

  Widget _buildCompanySelector() {
    final companies = _allowedCompanies;
    if (companies.isEmpty) {
      return const SizedBox.shrink();
    }

    if (companies.length == 1 && companies.first.id == _selectedCompanyId) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.business_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                companies.first.name.isNotEmpty
                    ? companies.first.name
                    : 'Primary Company',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCompanyId,
          isExpanded: true,
          onChanged: (value) {
            if (value == null || value == _selectedCompanyId) return;
            setState(() {
              _selectedCompanyId = value;
            });
            _loadDesignations();
          },
          items: companies
              .map(
                (company) => DropdownMenuItem<int>(
                  value: company.id,
                  child: Text(
                    company.name.isNotEmpty
                        ? company.name
                        : 'Company ${company.id}',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDesignationCard(DesignationModel designation) {
    final statusColor =
        designation.isActive ? AppColors.successColor : AppColors.warningColor;
    final statusText = designation.isActive ? 'Active' : 'Inactive';
    final toggleLabel =
        designation.isActive ? 'Mark Inactive' : 'Activate';

    return Card(
      key: ValueKey(designation.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.work_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          designation.name,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: AppTypography.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<_DesignationAction>(
                        tooltip: 'More actions',
                        onSelected: (action) =>
                            _handleDesignationAction(designation, action),
                        itemBuilder: (context) => [
                          PopupMenuItem<_DesignationAction>(
                            value: _DesignationAction.manageAccess,
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 18),
                                const SizedBox(width: 8),
                                const Text('Manage Access'),
                              ],
                            ),
                          ),
                          PopupMenuItem<_DesignationAction>(
                            value: _DesignationAction.edit,
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<_DesignationAction>(
                            value: _DesignationAction.toggleStatus,
                            child: Row(
                              children: [
                                Icon(
                                  designation.isActive
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(toggleLabel),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<_DesignationAction>(
                            value: _DesignationAction.delete,
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.errorColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      ReorderableDragStartListener(
                        index: _designations.indexOf(designation),
                        child: const Icon(Icons.drag_indicator_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Display order: ${designation.order}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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

  void _handleDesignationAction(
      DesignationModel designation, _DesignationAction action) {
    switch (action) {
      case _DesignationAction.manageAccess:
        _openDesignationAccess(designation);
        break;
      case _DesignationAction.edit:
        _editDesignation(designation);
        break;
      case _DesignationAction.toggleStatus:
        _toggleDesignationStatus(designation);
        break;
      case _DesignationAction.delete:
        _deleteDesignation(designation);
        break;
    }
  }

  Widget _buildSearchField() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Search designations...',
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionService.canManageDesignations();

    return DismissKeyboard(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Designations',
          showDrawer: false,
          showBackButton: true,
        ),

        floatingActionButton: canManage
            ? FloatingActionButton.extended(
                onPressed:
                    _selectedCompanyId == null ? null : _createDesignation,
                icon: const Icon(Icons.add),
                label: const Text('Add Designation'),
              )
            : null,
        body: Padding(
          padding: ResponsiveUtils.responsivePadding(context).copyWith(
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            
              if (!canManage)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningColor),
                  ),
                  child: Text(
                    'You do not have permission to manage designations. '
                    'Contact your administrator for access.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_allowedCompanies.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 480;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: _buildCompanySelector()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSearchField()),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCompanySelector(),
                        const SizedBox(height: 12),
                        _buildSearchField(),
                      ],
                    );
                  },
                )
              else
                _buildSearchField(),

              if (_isSavingOrder)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Saving new order...',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _designations.isEmpty
                        ? Center(
                            child: Text(
                              _selectedCompanyId == null
                                  ? 'Select a company to manage designations.'
                                  : 'No designations found.\nTap the button below to add one.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            onReorder: (oldIndex, newIndex) {
                              if (!canManage || _selectedCompanyId == null) {
                                SnackBarUtils.showError(
                                  context,
                                  message:
                                      'You do not have permission to reorder designations.',
                                );
                                return;
                              }
                              _reorderDesignations(oldIndex, newIndex);
                            },
                            itemCount: _designations.length,
                            buildDefaultDragHandles: false,
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom + 80,
                            ),
                            itemBuilder: (context, index) =>
                                _buildDesignationCard(_designations[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DesignationFormResult {
  final String name;
  final int? order;
  final String status;

  DesignationFormResult({
    required this.name,
    this.order,
    required this.status,
  });
}

class DesignationFormSheet extends StatefulWidget {
  final DesignationModel? designation;
  final int companyId;

  const DesignationFormSheet({
    super.key,
    this.designation,
    required this.companyId,
  });

  @override
  State<DesignationFormSheet> createState() => _DesignationFormSheetState();
}

class _DesignationFormSheetState extends State<DesignationFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _orderController;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.designation?.name ?? '');
    _orderController = TextEditingController(
      text: widget.designation != null ? '${widget.designation!.order}' : '',
    );
    _status = widget.designation?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final orderText = _orderController.text.trim();
    int? orderValue;

    if (orderText.isNotEmpty) {
      final parsed = int.tryParse(orderText);
      if (parsed == null || parsed <= 0) {
        SnackBarUtils.showError(
          context,
          message: 'Order must be a positive number',
        );
        return;
      }
      orderValue = parsed - 1;
    }

    Navigator.of(context).pop(
      DesignationFormResult(
        name: _nameController.text.trim(),
        order: orderValue,
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.designation != null;

    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: GestureDetector(
          onTap: () {},
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Designation' : 'Add Designation',
                              style: AppTypography.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Designation Name',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Designation name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orderController,
                        decoration: InputDecoration(
                          labelText: 'Display Order',
                          hintText: 'Leave blank to auto-assign',
                          border: const OutlineInputBorder(),
                          suffixText: 'Position',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleSubmit,
                          icon: Icon(isEditing
                              ? Icons.save_outlined
                              : Icons.add_circle_outline),
                          label: Text(isEditing ? 'Save Changes' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


