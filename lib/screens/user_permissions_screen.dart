import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/theme/app_typography.dart';
import '../models/site_user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class UserPermissionsScreen extends StatefulWidget {
  final SiteUserModel user;

  const UserPermissionsScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  static const List<String> _permissionKeys = [
    'can_create_site',
    'can_update_site',
    'can_delete_site',
    'can_update_site_address',
    'can_update_site_status',
    'can_create_task',
    'can_edit_task',
    'can_delete_task',
    'can_update_task_progress',
    'can_update_task_status',
    'can_assign_task',
    'can_create_issue',
    'can_edit_issue',
    'can_delete_issue',
    'can_update_issue_progress',
    'can_create_user',
    'can_edit_user',
    'can_delete_user',
    'can_assign_users_to_site',
    'can_remove_users_from_site',
    'can_invite_user',
    'can_mark_attendance',
    'can_view_attendance',
    'can_edit_attendance',
    'can_view_reports',
    'can_export_reports',
    'can_create_quality_check',
    'can_edit_quality_check',
    'can_delete_quality_check',
    'can_manage_materials',
    'can_create_po',
    'can_approve_po',
    'can_upload_images',
    'can_delete_images',
    'can_create_meeting',
    'can_edit_meeting',
    'can_delete_meeting',
    'can_manage_designations',
    'can_manage_company_settings',
    'can_view_petty_cash',
    'can_add_petty_cash',
    'can_edit_petty_cash',
  ];

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, bool> _permissions = {};
  Map<String, bool> _designationPermissions = {};
  Map<String, bool?> _userOverrides = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null || currentUser.apiToken.isEmpty) {
      SnackBarUtils.showError(context, message: 'Session expired. Please log in again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getUserAccess(
        apiToken: currentUser.apiToken,
        userId: widget.user.id,
      );



      if (response['status'] != 1 || response['data'] == null) {
        final message = response['message'] ?? 'Failed to load permissions';
        if (mounted) {
          setState(() {
            _isLoading = false;
            _permissions = {};
            _designationPermissions = {};
            _userOverrides = {for (final key in _permissionKeys) key: null};
          });
          SnackBarUtils.showError(context, message: message);
        }
        return;
      }

      final data = Map<String, dynamic>.from(response['data'] as Map);
      final designationRaw = data['designation_access'];
      final userAccessRaw = data['user_access'];
      final effectiveRaw = data['effective_permissions'];

      final Map<String, bool> designationPermissions = {};
      final Map<String, bool?> userOverrides = {};
      final Map<String, bool> effectivePermissions = {};

      for (final key in _permissionKeys) {
        final designationValue = _extractBool(designationRaw, key);
        final overrideValue = _extractNullableBool(userAccessRaw, key);
        final effectiveValue = _extractBool(
          effectiveRaw,
          key,
          fallback: overrideValue ?? designationValue,
        );

        designationPermissions[key] = designationValue;
        userOverrides[key] = overrideValue;
        effectivePermissions[key] = effectiveValue;
      }

      if (mounted) {
        setState(() {
          _designationPermissions = designationPermissions;
          _userOverrides = userOverrides;
          _permissions = effectivePermissions;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('ERROR UserPermissionsScreen: Failed to load permissions -> $e');
      print(stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, message: 'Failed to load permissions');
      }
    }
  }

  bool _extractBool(
    dynamic source,
    String key, {
    bool fallback = false,
  }) {
    if (source is Map) {
      final raw = source[key];
      if (raw == null) return fallback;
      if (raw is bool) return raw;
      if (raw is num) return raw == 1;
      if (raw is String) {
        final lower = raw.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
    }
    return fallback;
  }

  bool? _extractNullableBool(dynamic source, String key) {
    if (source is Map) {
      final raw = source[key];
      if (raw == null) return null;
      if (raw is bool) return raw;
      if (raw is num) return raw == 1;
      if (raw is String) {
        final lower = raw.toLowerCase();
        if (lower.isEmpty || lower == 'null') return null;
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
    }
    return null;
  }

  Future<void> _savePermissions() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Convert overrides to API format (exclude null values)
      final permissionsToSave = Map<String, dynamic>.from(_userOverrides);
      
      final response = await ApiService.updateUserAccess(
        apiToken: AuthService.currentUser!.apiToken,
        userId: widget.user.id,
        permissions: permissionsToSave,
      );

      setState(() {
        _isSaving = false;
      });

      if (response['status'] == 1) {
        SnackBarUtils.showSuccess(context, message: 'Permissions updated successfully');
        Navigator.pop(context);
      } else {
        SnackBarUtils.showError(context, message: response['message']);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      SnackBarUtils.showError(context, message: 'Failed to save permissions');
    }
  }

  void _togglePermission(String key) {
    setState(() {
      final currentValue = _userOverrides[key];
      final designationValue = _designationPermissions[key] ?? false;
      
      if (currentValue == null) {
        // Set to opposite of designation
        _userOverrides[key] = !designationValue;
      } else if (currentValue == designationValue) {
        // Reset to inherit from designation
        _userOverrides[key] = null;
      } else {
        // Toggle the override
        _userOverrides[key] = !currentValue;
      }
      
      // Update effective permissions
      _permissions[key] = _userOverrides[key] ?? designationValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Permissions',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            Text(
              widget.user.fullName,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton.icon(
              onPressed: _savePermissions,
              icon: const Icon(Icons.save, color: Colors.white, size: 20),
              label: Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: ResponsiveUtils.responsivePadding(context),
              children: [
                _buildSection(
                  'Site Management',
                  Icons.location_city,
                  [
                    'can_create_site',
                    'can_update_site',
                    'can_delete_site',
                    'can_update_site_address',
                    'can_update_site_status',
                  ],
                ),
                _buildSection(
                  'Task Management',
                  Icons.assignment,
                  [
                    'can_create_task',
                    'can_edit_task',
                    'can_delete_task',
                    'can_update_task_progress',
                    'can_update_task_status',
                    'can_assign_task',
                  ],
                ),
                _buildSection(
                  'Issue Management',
                  Icons.bug_report,
                  [
                    'can_create_issue',
                    'can_edit_issue',
                    'can_delete_issue',
                    'can_update_issue_progress',
                  ],
                ),
                _buildSection(
                  'User Management',
                  Icons.people,
                  [
                    'can_create_user',
                    'can_edit_user',
                    'can_delete_user',
                    'can_assign_users_to_site',
                    'can_remove_users_from_site',
                  ],
                ),
                _buildSection(
                  'Attendance',
                  Icons.schedule,
                  [
                    'can_mark_attendance',
                    'can_view_attendance',
                    'can_edit_attendance',
                  ],
                ),
                _buildSection(
                  'Reports',
                  Icons.analytics,
                  [
                    'can_view_reports',
                    'can_export_reports',
                  ],
                ),
                _buildSection(
                  'Quality Check',
                  Icons.fact_check,
                  [
                    'can_create_quality_check',
                    'can_edit_quality_check',
                    'can_delete_quality_check',
                  ],
                ),
                _buildSection(
                  'Material & PO',
                  Icons.inventory,
                  [
                    'can_manage_materials',
                    'can_create_po',
                    'can_approve_po',
                  ],
                ),
                _buildSection(
                  'Media',
                  Icons.photo_library,
                  [
                    'can_upload_images',
                    'can_delete_images',
                  ],
                ),
                _buildSection(
                  'Meetings',
                  Icons.event,
                  [
                    'can_create_meeting',
                    'can_edit_meeting',
                    'can_delete_meeting',
                  ],
                ),
                _buildSection(
                  'Administrative',
                  Icons.admin_panel_settings,
                  [
                    'can_manage_designations',
                    'can_manage_company_settings',
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> permissions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...permissions.map((permission) => _buildPermissionRow(permission)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String permission) {
    final displayName = _formatPermissionName(permission);
    final isEnabled = _permissions[permission] ?? false;
    final designationValue = _designationPermissions[permission] ?? false;
    final userOverride = _userOverrides[permission];
    final isOverridden = userOverride != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (isOverridden)
                  Text(
                    'From Designation: ${designationValue ? "Yes" : "No"})',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warningColor,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOverridden)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _userOverrides[permission] = null;
                      _permissions[permission] = designationValue;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppColors.warningColor,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Switch(
                value: isEnabled,
                onChanged: (value) => _togglePermission(permission),
                activeColor: AppColors.successColor,
              ),
            ],
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
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

