import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/designation_model.dart';
import '../services/designation_service.dart';
import '../widgets/custom_search_bar.dart';

class DesignationPermissionsScreen extends StatefulWidget {
  final DesignationModel designation;

  const DesignationPermissionsScreen({
    super.key,
    required this.designation,
  });

  @override
  State<DesignationPermissionsScreen> createState() =>
      _DesignationPermissionsScreenState();
}

class _DesignationPermissionsScreenState
    extends State<DesignationPermissionsScreen> {
  static const Map<String, List<String>> _permissionGroups = {
    'Site Management': [
      'can_create_site',
      'can_update_site',
      'can_delete_site',
      'can_update_site_address',
      'can_update_site_status',
    ],
    'Task Management': [
      'can_create_task',
      'can_edit_task',
      'can_delete_task',
      'can_update_task_progress',
      'can_update_task_status',
      'can_assign_task',
    ],
    'Issue Management': [
      'can_create_issue',
      'can_edit_issue',
      'can_delete_issue',
      'can_update_issue_progress',
    ],
    'User Management': [
      'can_create_user',
      'can_edit_user',
      'can_delete_user',
      'can_assign_users_to_site',
      'can_remove_users_from_site',
    ],
    'Attendance': [
      'can_mark_attendance',
      'can_view_attendance',
      'can_edit_attendance',
    ],
    'Reports': [
      'can_view_reports',
      'can_export_reports',
    ],
    'Quality Check': [
      'can_create_quality_check',
      'can_edit_quality_check',
      'can_delete_quality_check',
    ],
    'Material & PO': [
      'can_manage_materials',
      'can_create_po',
      'can_approve_po',
    ],
    'Media': [
      'can_upload_images',
      'can_delete_images',
    ],
    'Meetings': [
      'can_create_meeting',
      'can_edit_meeting',
      'can_delete_meeting',
    ],
    'Administrative': [
      'can_manage_designations',
      'can_manage_company_settings',
      'can_invite_user',
    ],
    'Petty Cash': [
      'can_view_petty_cash',
      'can_add_petty_cash',
      'can_edit_petty_cash',
    ],
  };

  bool _isLoading = false;
  bool _isSaving = false;
  String _searchQuery = '';
  Map<String, bool> _permissions = {
    for (final group in _permissionGroups.values)
      for (final permission in group) permission: false,
  };

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final data =
        await DesignationService.getDesignationAccess(designationId: widget.designation.id);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (data == null) {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
      return;
    }

    final updatedPermissions = Map<String, bool>.from(_permissions);

    data.forEach((key, value) {
      if (updatedPermissions.containsKey(key)) {
        updatedPermissions[key] = value == true ||
            value == 1 ||
            (value is String && value.toLowerCase() == 'true');
      }
    });

    setState(() {
      _permissions = updatedPermissions;
    });
  }

  Future<void> _savePermissions() async {
    setState(() {
      _isSaving = true;
    });

    final payload = Map<String, dynamic>.from(_permissions);
    final success = await DesignationService.updateDesignationAccess(
      designationId: widget.designation.id,
      permissions: payload,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      SnackBarUtils.showSuccess(
        context,
        message: 'Permissions updated successfully',
      );
      Navigator.of(context).pop();
    } else {
      SnackBarUtils.showError(
        context,
        message: DesignationService.errorMessage,
      );
    }
  }

  void _togglePermission(String key, bool value) {
    setState(() {
      _permissions[key] = value;
    });
  }

  void _toggleGroup(String groupName, bool value) {
    final permissions = _permissionGroups[groupName] ?? [];
    setState(() {
      for (final permission in permissions) {
        _permissions[permission] = value;
      }
    });
  }

  void _toggleAll(bool value) {
    setState(() {
      _permissions.updateAll((key, _) => value);
    });
  }

  bool _matchesSearch(String permissionKey) {
    if (_searchQuery.isEmpty) return true;
    final label = _formatPermissionName(permissionKey).toLowerCase();
    return label.contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _permissionGroups.entries.where(
      (entry) => entry.value.any(_matchesSearch),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.designation.name} Permissions',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton.icon(
              onPressed: _savePermissions,
              icon: const Icon(Icons.save_alt, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomSearchBar(
                        hintText: 'Search permissions',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleAll(true),
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Grant All', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleAll(false),
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Revoke All', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredGroups.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 64),
                            child: Text(
                              'No permissions match your search.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) {
                            final entry = filteredGroups.elementAt(index);
                            return _buildPermissionGroup(
                              context,
                              entry.key,
                              entry.value.where(_matchesSearch).toList(),
                            );
                          },
                        ),
                ),
                if (_isSaving)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Saving changes...',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPermissionGroup(
    BuildContext context,
    String groupName,
    List<String> permissions,
  ) {
    final groupPermissions = _permissionGroups[groupName] ?? [];
    final allEnabled =
        groupPermissions.isNotEmpty && groupPermissions.every((key) => _permissions[key] == true);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Icon(
          Icons.shield_moon_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        title: Text(
          groupName,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: allEnabled,
              onChanged: (value) => _toggleGroup(groupName, value),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: permissions.map((permissionKey) => _buildPermissionRow(permissionKey)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String permissionKey) {
    final isEnabled = _permissions[permissionKey] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatPermissionName(permissionKey),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) => _togglePermission(permissionKey, value),
            activeColor: AppColors.successColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  String _formatPermissionName(String permission) {
    return permission
        .replaceAll('can_', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }
}


