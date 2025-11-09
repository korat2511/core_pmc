import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  // App-level permission screen tracking
  static const String _permissionScreenShownKey = 'permission_screen_shown';

  // Check if permission screen should be shown
  static Future<bool> shouldShowPermissionScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getString(_permissionScreenShownKey);
    return shown != 'true';
  }

  // Mark permission screen as shown
  static Future<void> markPermissionScreenShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_permissionScreenShownKey, 'true');
  }

  // Reset permission tracking (for testing/debugging)
  static Future<void> resetPermissionTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionScreenShownKey);
  }

  // Cache for user permissions
  static Map<String, bool>? _cachedPermissions;

  /// Initialize permissions from login response
  static void setPermissions(Map<String, dynamic>? permissions) {
    if (permissions != null) {
      _cachedPermissions = permissions.map(
        (key, value) => MapEntry(key, value == true || value == 1),
      );
    } else {
      _cachedPermissions = {};
    }
  }

  /// Clear cached permissions (on logout)
  static void clearPermissions() {
    _cachedPermissions = null;
  }

  /// Check if user has a specific permission
  static bool hasPermission(String permission) {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    // Use cached permissions if available
    if (_cachedPermissions != null && _cachedPermissions!.containsKey(permission)) {
      return _cachedPermissions![permission] ?? false;
    }

    // Fallback: check if user is admin
    return currentUser.isAdmin;
  }

  /// Check if user has all specified permissions
  static bool hasAllPermissions(List<String> permissions) {
    for (final permission in permissions) {
      if (!hasPermission(permission)) {
        return false;
      }
    }
    return true;
  }

  /// Check if user has any of the specified permissions
  static bool hasAnyPermission(List<String> permissions) {
    for (final permission in permissions) {
      if (hasPermission(permission)) {
        return true;
      }
    }
    return false;
  }

  // Site Management Permissions
  static bool canCreateSite() => hasPermission('can_create_site');
  static bool canUpdateSite() => hasPermission('can_update_site');
  static bool canDeleteSite() => hasPermission('can_delete_site');
  static bool canUpdateSiteAddress() => hasPermission('can_update_site_address');
  static bool canUpdateSiteStatus() => hasPermission('can_update_site_status');

  // Task Management Permissions
  static bool canCreateTask() => hasPermission('can_create_task');
  static bool canEditTask() => hasPermission('can_edit_task');
  static bool canDeleteTask() => hasPermission('can_delete_task');
  static bool canUpdateTaskProgress() => hasPermission('can_update_task_progress');
  static bool canUpdateTaskStatus() => hasPermission('can_update_task_status');
  static bool canAssignTask() => hasPermission('can_assign_task');

  // Issue Management Permissions
  static bool canCreateIssue() => hasPermission('can_create_issue');
  static bool canEditIssue() => hasPermission('can_edit_issue');
  static bool canDeleteIssue() => hasPermission('can_delete_issue');
  static bool canUpdateIssueProgress() => hasPermission('can_update_issue_progress');

  // User Management Permissions
  static bool canCreateUser() => hasPermission('can_create_user');
  static bool canEditUser() => hasPermission('can_edit_user');
  static bool canDeleteUser() => hasPermission('can_delete_user');
  static bool canAssignUsersToSite() => hasPermission('can_assign_users_to_site');
  static bool canRemoveUsersFromSite() => hasPermission('can_remove_users_from_site');
  static bool canInviteUser() => hasPermission('can_invite_user');

  // Attendance Permissions
  static bool canMarkAttendance() => hasPermission('can_mark_attendance');
  static bool canViewAttendance() => hasPermission('can_view_attendance');
  static bool canEditAttendance() => hasPermission('can_edit_attendance');

  // Report Permissions
  static bool canViewReports() => hasPermission('can_view_reports');
  static bool canExportReports() => hasPermission('can_export_reports');

  // Quality Check Permissions
  static bool canCreateQualityCheck() => hasPermission('can_create_quality_check');
  static bool canEditQualityCheck() => hasPermission('can_edit_quality_check');
  static bool canDeleteQualityCheck() => hasPermission('can_delete_quality_check');

  // Material Management Permissions
  static bool canManageMaterials() => hasPermission('can_manage_materials');
  static bool canCreatePO() => hasPermission('can_create_po');
  static bool canApprovePO() => hasPermission('can_approve_po');

  // Album/Media Permissions
  static bool canUploadImages() => hasPermission('can_upload_images');
  static bool canDeleteImages() => hasPermission('can_delete_images');

  // Meeting Permissions
  static bool canCreateMeeting() => hasPermission('can_create_meeting');
  static bool canEditMeeting() => hasPermission('can_edit_meeting');
  static bool canDeleteMeeting() => hasPermission('can_delete_meeting');

  // Administrative Permissions
  static bool canManageDesignations() => hasPermission('can_manage_designations');
  static bool canManageCompanySettings() => hasPermission('can_manage_company_settings');

  /// Special permission checks with additional logic

  /// Can edit task - checks permission OR if user is creator OR assigned
  static bool canEditTaskWithContext(int taskCreatorId, List<int> assignedUserIds) {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    // Check permission
    if (canEditTask()) return true;

    // Check if user is creator
    if (currentUser.id == taskCreatorId) return true;

    // Check if user is assigned
    if (assignedUserIds.contains(currentUser.id)) return true;

    return false;
  }

  /// Can delete task - checks permission OR if user is creator
  static bool canDeleteTaskWithContext(int taskCreatorId) {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    // Check permission
    if (canDeleteTask()) return true;

    // Check if user is creator
    if (currentUser.id == taskCreatorId) return true;

    return false;
  }

  /// Can update task progress - checks permission OR if user is creator OR assigned
  static bool canUpdateTaskProgressWithContext(int taskCreatorId, List<int> assignedUserIds) {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    // Check permission
    if (canUpdateTaskProgress()) return true;

    // Check if user is creator
    if (currentUser.id == taskCreatorId) return true;

    // Check if user is assigned
    if (assignedUserIds.contains(currentUser.id)) return true;

    return false;
  }
}
