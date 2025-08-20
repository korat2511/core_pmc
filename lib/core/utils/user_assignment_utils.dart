import 'package:flutter/material.dart';
import '../../models/site_model.dart';
import '../../models/site_user_model.dart';
import '../../services/all_user_service.dart';
import '../../services/site_user_service.dart';
import '../../widgets/user_assignment_modal.dart';
import 'snackbar_utils.dart';

class UserAssignmentUtils {
  static Future<void> showUserAssignmentModal({
    required BuildContext context,
    required SiteModel site,
    VoidCallback? onUserAssigned,
    VoidCallback? onUserRemoved,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Load all users and site users in parallel
      final allUserService = AllUserService();
      final siteUserService = SiteUserService();

      final allUsersFuture = allUserService.getAllUsers();
      final siteUsersFuture = siteUserService.getUsersBySite(siteId: site.id);

      final allUsersSuccess = await allUsersFuture;
      final siteUsersSuccess = await siteUsersFuture;

      // Close loading dialog
      Navigator.pop(context);

      if (!allUsersSuccess) {
        SnackBarUtils.showError(
          context,
          message: allUserService.errorMessage,
        );
        return;
      }

      if (!siteUsersSuccess) {
        SnackBarUtils.showError(
          context,
          message: siteUserService.errorMessage,
        );
        return;
      }

      // Show the modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => UserAssignmentModal(
            site: site,
            allUsers: allUserService.users,
            siteUsers: siteUserService.users,
            onUserAssigned: onUserAssigned,
            onUserRemoved: onUserRemoved,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      SnackBarUtils.showError(
        context,
        message: 'Failed to load users: $e',
      );
    }
  }
}
