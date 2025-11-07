class PermissionModel {
  // Site Management
  final bool canCreateSite;
  final bool canUpdateSite;
  final bool canDeleteSite;
  final bool canUpdateSiteAddress;
  final bool canUpdateSiteStatus;
  
  // Task Management
  final bool canCreateTask;
  final bool canEditTask;
  final bool canDeleteTask;
  final bool canUpdateTaskProgress;
  final bool canUpdateTaskStatus;
  final bool canAssignTask;
  
  // Issue Management
  final bool canCreateIssue;
  final bool canEditIssue;
  final bool canDeleteIssue;
  final bool canUpdateIssueProgress;
  
  // User Management
  final bool canCreateUser;
  final bool canEditUser;
  final bool canDeleteUser;
  final bool canAssignUsersToSite;
  final bool canRemoveUsersFromSite;
  
  // Attendance
  final bool canMarkAttendance;
  final bool canViewAttendance;
  final bool canEditAttendance;
  
  // Reports
  final bool canViewReports;
  final bool canExportReports;
  
  // Quality Check
  final bool canCreateQualityCheck;
  final bool canEditQualityCheck;
  final bool canDeleteQualityCheck;
  
  // Material Management
  final bool canManageMaterials;
  final bool canCreatePO;
  final bool canApprovePO;
  
  // Album/Media
  final bool canUploadImages;
  final bool canDeleteImages;
  
  // Meetings
  final bool canCreateMeeting;
  final bool canEditMeeting;
  final bool canDeleteMeeting;
  
  // Administrative
  final bool canManageDesignations;
  final bool canManageCompanySettings;

  PermissionModel({
    this.canCreateSite = false,
    this.canUpdateSite = false,
    this.canDeleteSite = false,
    this.canUpdateSiteAddress = false,
    this.canUpdateSiteStatus = false,
    this.canCreateTask = false,
    this.canEditTask = false,
    this.canDeleteTask = false,
    this.canUpdateTaskProgress = false,
    this.canUpdateTaskStatus = false,
    this.canAssignTask = false,
    this.canCreateIssue = false,
    this.canEditIssue = false,
    this.canDeleteIssue = false,
    this.canUpdateIssueProgress = false,
    this.canCreateUser = false,
    this.canEditUser = false,
    this.canDeleteUser = false,
    this.canAssignUsersToSite = false,
    this.canRemoveUsersFromSite = false,
    this.canMarkAttendance = false,
    this.canViewAttendance = false,
    this.canEditAttendance = false,
    this.canViewReports = false,
    this.canExportReports = false,
    this.canCreateQualityCheck = false,
    this.canEditQualityCheck = false,
    this.canDeleteQualityCheck = false,
    this.canManageMaterials = false,
    this.canCreatePO = false,
    this.canApprovePO = false,
    this.canUploadImages = false,
    this.canDeleteImages = false,
    this.canCreateMeeting = false,
    this.canEditMeeting = false,
    this.canDeleteMeeting = false,
    this.canManageDesignations = false,
    this.canManageCompanySettings = false,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      canCreateSite: json['can_create_site'] == true || json['can_create_site'] == 1,
      canUpdateSite: json['can_update_site'] == true || json['can_update_site'] == 1,
      canDeleteSite: json['can_delete_site'] == true || json['can_delete_site'] == 1,
      canUpdateSiteAddress: json['can_update_site_address'] == true || json['can_update_site_address'] == 1,
      canUpdateSiteStatus: json['can_update_site_status'] == true || json['can_update_site_status'] == 1,
      canCreateTask: json['can_create_task'] == true || json['can_create_task'] == 1,
      canEditTask: json['can_edit_task'] == true || json['can_edit_task'] == 1,
      canDeleteTask: json['can_delete_task'] == true || json['can_delete_task'] == 1,
      canUpdateTaskProgress: json['can_update_task_progress'] == true || json['can_update_task_progress'] == 1,
      canUpdateTaskStatus: json['can_update_task_status'] == true || json['can_update_task_status'] == 1,
      canAssignTask: json['can_assign_task'] == true || json['can_assign_task'] == 1,
      canCreateIssue: json['can_create_issue'] == true || json['can_create_issue'] == 1,
      canEditIssue: json['can_edit_issue'] == true || json['can_edit_issue'] == 1,
      canDeleteIssue: json['can_delete_issue'] == true || json['can_delete_issue'] == 1,
      canUpdateIssueProgress: json['can_update_issue_progress'] == true || json['can_update_issue_progress'] == 1,
      canCreateUser: json['can_create_user'] == true || json['can_create_user'] == 1,
      canEditUser: json['can_edit_user'] == true || json['can_edit_user'] == 1,
      canDeleteUser: json['can_delete_user'] == true || json['can_delete_user'] == 1,
      canAssignUsersToSite: json['can_assign_users_to_site'] == true || json['can_assign_users_to_site'] == 1,
      canRemoveUsersFromSite: json['can_remove_users_from_site'] == true || json['can_remove_users_from_site'] == 1,
      canMarkAttendance: json['can_mark_attendance'] == true || json['can_mark_attendance'] == 1,
      canViewAttendance: json['can_view_attendance'] == true || json['can_view_attendance'] == 1,
      canEditAttendance: json['can_edit_attendance'] == true || json['can_edit_attendance'] == 1,
      canViewReports: json['can_view_reports'] == true || json['can_view_reports'] == 1,
      canExportReports: json['can_export_reports'] == true || json['can_export_reports'] == 1,
      canCreateQualityCheck: json['can_create_quality_check'] == true || json['can_create_quality_check'] == 1,
      canEditQualityCheck: json['can_edit_quality_check'] == true || json['can_edit_quality_check'] == 1,
      canDeleteQualityCheck: json['can_delete_quality_check'] == true || json['can_delete_quality_check'] == 1,
      canManageMaterials: json['can_manage_materials'] == true || json['can_manage_materials'] == 1,
      canCreatePO: json['can_create_po'] == true || json['can_create_po'] == 1,
      canApprovePO: json['can_approve_po'] == true || json['can_approve_po'] == 1,
      canUploadImages: json['can_upload_images'] == true || json['can_upload_images'] == 1,
      canDeleteImages: json['can_delete_images'] == true || json['can_delete_images'] == 1,
      canCreateMeeting: json['can_create_meeting'] == true || json['can_create_meeting'] == 1,
      canEditMeeting: json['can_edit_meeting'] == true || json['can_edit_meeting'] == 1,
      canDeleteMeeting: json['can_delete_meeting'] == true || json['can_delete_meeting'] == 1,
      canManageDesignations: json['can_manage_designations'] == true || json['can_manage_designations'] == 1,
      canManageCompanySettings: json['can_manage_company_settings'] == true || json['can_manage_company_settings'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_create_site': canCreateSite,
      'can_update_site': canUpdateSite,
      'can_delete_site': canDeleteSite,
      'can_update_site_address': canUpdateSiteAddress,
      'can_update_site_status': canUpdateSiteStatus,
      'can_create_task': canCreateTask,
      'can_edit_task': canEditTask,
      'can_delete_task': canDeleteTask,
      'can_update_task_progress': canUpdateTaskProgress,
      'can_update_task_status': canUpdateTaskStatus,
      'can_assign_task': canAssignTask,
      'can_create_issue': canCreateIssue,
      'can_edit_issue': canEditIssue,
      'can_delete_issue': canDeleteIssue,
      'can_update_issue_progress': canUpdateIssueProgress,
      'can_create_user': canCreateUser,
      'can_edit_user': canEditUser,
      'can_delete_user': canDeleteUser,
      'can_assign_users_to_site': canAssignUsersToSite,
      'can_remove_users_from_site': canRemoveUsersFromSite,
      'can_mark_attendance': canMarkAttendance,
      'can_view_attendance': canViewAttendance,
      'can_edit_attendance': canEditAttendance,
      'can_view_reports': canViewReports,
      'can_export_reports': canExportReports,
      'can_create_quality_check': canCreateQualityCheck,
      'can_edit_quality_check': canEditQualityCheck,
      'can_delete_quality_check': canDeleteQualityCheck,
      'can_manage_materials': canManageMaterials,
      'can_create_po': canCreatePO,
      'can_approve_po': canApprovePO,
      'can_upload_images': canUploadImages,
      'can_delete_images': canDeleteImages,
      'can_create_meeting': canCreateMeeting,
      'can_edit_meeting': canEditMeeting,
      'can_delete_meeting': canDeleteMeeting,
      'can_manage_designations': canManageDesignations,
      'can_manage_company_settings': canManageCompanySettings,
    };
  }
}

