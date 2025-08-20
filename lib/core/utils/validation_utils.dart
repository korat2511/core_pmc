import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ValidationUtils {
  /// Check if current user can create sites
  /// Only users with IDs 1, 6, 57 can create sites
  static bool canCreateSite(BuildContext context) {
    final UserModel? currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    return [1, 6, 57, 2].contains(currentUser.id);
  }

}
