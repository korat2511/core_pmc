import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/task_detail_model.dart';
import '../../models/task_model.dart';

class ValidationUtils {
  /// Check if current user can create sites
  /// Only users with IDs 1, 6, 57 can create sites
  static bool canCreateSite(BuildContext context) {
    final UserModel? currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    return [1, 6, 57, 51].contains(currentUser.id);
  }

  /// Check if current user can change "Decision Pending From"
  /// Only users with designation ID 1, task creators, and assigned users can change this
  static bool canChangeDecisionPendingFrom(TaskDetailModel taskDetail) {
    final UserModel? currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    // Check if user has designation ID 1 (assuming userType is the designation ID)
    if (currentUser.userType == 1) return true;
    
    // Check if user is the task creator
    if (currentUser.id == taskDetail.createdBy) return true;
    
    // Check if user is assigned to the task
    if (taskDetail.assignTo != null && taskDetail.assignTo!.isNotEmpty) {
      final assignedUserIds = taskDetail.assignTo!
          .split(',')
          .map((id) => int.tryParse(id.trim()) ?? 0)
          .where((id) => id > 0)
          .toList();
      
      if (assignedUserIds.contains(currentUser.id)) return true;
    }
    
    return false;
  }

  /// Check if current user can update a task
  /// For cat_sub_id 2,3,4,6: Only task creators, user type 1, and assigned users can update
  /// For other task types: No restriction (handled by other validation)
  static bool canUpdateTask(TaskModel task) {
    final UserModel? currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    // Check if this is a simple task (cat_sub_id 2,3,4,6)
    final simpleTaskCategories = ['decision', 'drawing', 'quotation', 'selection'];
    final isSimpleTask = simpleTaskCategories.contains(task.categoryName.toLowerCase());
    
    if (!isSimpleTask) {
      // For non-simple tasks, no restriction (other validation will handle)
      return true;
    }
    
    // For simple tasks, check permissions:
    
    // Check if user has user type 1 (admin/supervisor)
    if (currentUser.userType == 1) return true;
    
    // Check if user is the task creator
    if (currentUser.id == task.createdBy) return true;
    
    // Check if user is assigned to the task
    if (task.assign.isNotEmpty) {
      final assignedUserIds = task.assign.map((user) => user.id).toList();
      if (assignedUserIds.contains(currentUser.id)) return true;
    }
    
    return false;
  }

  /// Check if current user can accept a task
  /// For cat_sub_id 2,3,4,6: Only task creators and user type 1 can accept
  /// For other task types: No restriction (handled by other validation)
  static bool canAcceptTask(TaskModel task) {
    final UserModel? currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    // Check if this is a simple task (cat_sub_id 2,3,4,6)
    final simpleTaskCategories = ['decision', 'drawing', 'quatation', 'selection'];
    final isSimpleTask = simpleTaskCategories.contains(task.categoryName.toLowerCase());
    
    if (!isSimpleTask) {
      // For non-simple tasks, no restriction (other validation will handle)
      return true;
    }
    
    // For simple tasks, check permissions:
    
    // Check if user has user type 1 (admin/supervisor)
    if (currentUser.userType == 1) return true;
    
    // Check if user is the task creator
    if (currentUser.id == task.createdBy) return true;
    
    return false;
  }

  static bool canDeleteTask(TaskModel task) {
    final UserModel? currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    // Check if user has user type 1 (admin/supervisor)
    if (currentUser.userType == 1) return true;

    // Check if user is the task creator
    if (currentUser.id == task.createdBy) return true;

    return false;
  }

  /// Check if task is completed (progress = 100%)
  static bool isTaskCompleted(TaskModel task) {
    return task.progressPercentage >= 100;
  }

  /// Check if task is completed (progress = 100%)
  static bool isTaskDetailCompleted(TaskDetailModel taskDetail) {
    return (taskDetail.progress ?? 0) >= 100;
  }

}
