import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/site_model.dart';
import '../../models/site_user_model.dart';
import '../../models/user_model.dart';
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

  // Simple user assignment for task creation - only site users
  static Future<List<UserModel>> showSimpleUserAssignmentModal({
    required BuildContext context,
    required int siteId,
    List<UserModel>? preSelectedUsers,
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

      // Load site users only
      final siteUserService = SiteUserService();
      final success = await siteUserService.getUsersBySite(siteId: siteId);

      // Close loading dialog
      Navigator.pop(context);

      if (!success) {
        SnackBarUtils.showError(
          context,
          message: siteUserService.errorMessage,
        );
        return preSelectedUsers ?? [];
      }

      if (siteUserService.users.isEmpty) {
        SnackBarUtils.showInfo(
          context,
          message: 'No users found for this site',
        );
        return preSelectedUsers ?? [];
      }

      // Convert preSelectedUsers to IDs for the modal
      final preSelectedIds = preSelectedUsers?.map((user) => user.id).toList() ?? [];

      // Show the modal and return selected users
      final selectedUserIds = await showModalBottomSheet<List<int>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => _SimpleUserAssignmentModal(
          siteUsers: siteUserService.users,
          preSelectedIds: preSelectedIds,
        ),
      );

      if (selectedUserIds == null) {
        return preSelectedUsers ?? [];
      }

      // Convert selected IDs back to UserModel objects
      return selectedUserIds.map((id) {
        final siteUser = siteUserService.users.firstWhere((user) => user.id == id);
        return UserModel(
          id: siteUser.id,
          firstName: siteUser.firstName,
          lastName: siteUser.lastName,
          mobile: siteUser.mobile,
          email: siteUser.email,
          userType: siteUser.userType,
          status: siteUser.status,
          lastActiveTime: siteUser.createdAt,
          createdAt: siteUser.createdAt,
          updatedAt: siteUser.updatedAt,
          apiToken: '',
        );
      }).toList();
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      SnackBarUtils.showError(
        context,
        message: 'Failed to load users: $e',
      );
      return preSelectedUsers ?? [];
    }
  }
}

class _SimpleUserAssignmentModal extends StatefulWidget {
  final List<SiteUserModel> siteUsers;
  final List<int> preSelectedIds;

  const _SimpleUserAssignmentModal({
    required this.siteUsers,
    required this.preSelectedIds,
  });

  @override
  State<_SimpleUserAssignmentModal> createState() => _SimpleUserAssignmentModalState();
}

class _SimpleUserAssignmentModalState extends State<_SimpleUserAssignmentModal> {
  late List<int> _selectedUserIds;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = List.from(widget.preSelectedIds);
  }

  void _toggleUserSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Assign Users to Task',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Users list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.siteUsers.length,
                        itemBuilder: (context, index) {
                          final user = widget.siteUsers[index];
                          final isAssigned = _selectedUserIds.contains(user.id);

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isAssigned) {
                                  _selectedUserIds.remove(user.id);
                                } else {
                                  _selectedUserIds.add(user.id);
                                }
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isAssigned
                                    ? AppColors.primaryColor.withOpacity(0.1)
                                    : AppColors.surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAssigned
                                      ? AppColors.primaryColor
                                      : AppColors.borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // User avatar
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),

                                  // User info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName,
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          user.email,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Assign/Remove button
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        if (isAssigned) {
                                          _selectedUserIds.remove(user.id);
                                        } else {
                                          _selectedUserIds.add(user.id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAssigned
                                            ? AppColors.errorColor
                                            : AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isAssigned ? 'Remove' : 'Assign',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, _selectedUserIds),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: AppColors.textWhite,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Update Assignment',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
