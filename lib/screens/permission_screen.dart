import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final Map<Permission, bool> _permissionStatus = {};
  bool _isLoading = false;

  final List<PermissionItem> _permissions = [
    PermissionItem(
      permission: Permission.camera,
      title: 'Camera',
      description: 'Access to take photos and videos',
      icon: Icons.camera_alt_outlined,
      color: AppColors.primaryColor,
    ),
    PermissionItem(
      permission: Permission.location,
      title: 'Location',
      description: 'Access to your location for site tracking',
      icon: Icons.location_on_outlined,
      color: AppColors.successColor,
    ),
    PermissionItem(
      permission: Permission.storage,
      title: 'Storage',
      description: 'Access to save and manage files',
      icon: Icons.folder_outlined,
      color: AppColors.warningColor,
    ),
    PermissionItem(
      permission: Permission.manageExternalStorage,
      title: 'Files & Media',
      description: 'Access to manage files and media',
      icon: Icons.file_copy_outlined,
      color: AppColors.infoColor,
    ),
    PermissionItem(
      permission: Permission.contacts,
      title: 'Contacts',
      description: 'Access to your contacts for team communication',
      icon: Icons.contacts_outlined,
      color: AppColors.secondaryColor,
    ),
    PermissionItem(
      permission: Permission.microphone,
      title: 'Voice & Audio',
      description: 'Access to microphone for voice notes',
      icon: Icons.mic_outlined,
      color: AppColors.errorColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    print('Checking initial permission status...');
    for (var permission in _permissions) {
      final status = await permission.permission.status;
      print('${permission.title} initial status: $status');
      _permissionStatus[permission.permission] = status.isGranted;
    }
    setState(() {});
  }

  Future<void> _requestPermission(PermissionItem permissionItem) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await permissionItem.permission.request();
      setState(() {
        _permissionStatus[permissionItem.permission] = status.isGranted;
        _isLoading = false;
      });

      if (status.isGranted) {
        SnackBarUtils.showSuccess(
          context,
          message: '${permissionItem.title} permission granted!',
        );
      } else if (status.isDenied) {
        SnackBarUtils.showWarning(
          context,
          message: '${permissionItem.title} permission denied',
        );
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog(permissionItem);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to request ${permissionItem.title} permission',
      );
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting to request all permissions one by one...');
      
      for (int i = 0; i < _permissions.length; i++) {
        final permission = _permissions[i];
        print('Requesting ${permission.title} permission (${i + 1}/${_permissions.length})...');
        
        // Show a dialog to inform user about the permission
        bool shouldContinue = await _showPermissionInfoDialog(permission);
        
        if (shouldContinue) {
          // Request the permission
          final status = await permission.permission.request();
          print('${permission.title} permission status after request: $status');
          _permissionStatus[permission.permission] = status.isGranted;
        } else {
          print('User skipped ${permission.title} permission');
          _permissionStatus[permission.permission] = false;
        }
        
        // Update UI to show current permission status
        setState(() {});
        
        // Add a small delay between permission requests
        if (i < _permissions.length - 1) {
          await Future.delayed(Duration(milliseconds: 300));
        }
      }
      
      setState(() {
        _isLoading = false;
      });

      print('All permissions requested. Status: $_permissionStatus');
      
      // Check if any permissions are permanently denied
      bool hasPermanentlyDenied = false;
      for (var permission in _permissions) {
        final finalStatus = await permission.permission.status;
        if (finalStatus.isPermanentlyDenied) {
          hasPermanentlyDenied = true;
          break;
        }
      }
      
      if (hasPermanentlyDenied) {
        print('Some permissions are permanently denied, showing settings dialog');
        SnackBarUtils.showWarning(
          context,
          message: 'Some permissions are permanently denied. Please enable them in Settings.',
        );
        _showSettingsDialog();
      } else {
        print('All permissions processed successfully');
        SnackBarUtils.showSuccess(
          context,
          message: 'All permissions requested successfully!',
        );
        // Mark that permission screen was shown and navigate to next screen
        await PermissionService.markPermissionScreenShown();
        _proceedToApp();
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      setState(() {
        _isLoading = false;
      });
      SnackBarUtils.showError(
        context,
        message: 'Failed to request some permissions',
      );
    }
  }

  void _showPermissionDialog(PermissionItem permissionItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          '${permissionItem.title} permission is required for this app to function properly. Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissions Required'),
        content: Text(
          'Some permissions are permanently denied. Please enable them in Settings to use all app features.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToApp();
            },
            child: Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showPermissionInfoDialog(PermissionItem permission) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: permission.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                permission.icon,
                color: permission.color,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '${permission.title} Permission',
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '${permission.description}\n\nThis permission is required for the app to function properly.\n\nYou can skip this permission and continue with the next one.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('Skip This'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Grant Permission'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _proceedToApp() async {
    // Mark that permission screen was shown (regardless of user choice)
    await PermissionService.markPermissionScreenShown();
    
    if (AuthService.isLoggedIn()) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // Method to reset permissions for testing (call this if permissions are permanently denied)
  Future<void> _resetPermissionsForTesting() async {
    try {
      // Reset permission tracking
      await PermissionService.resetPermissionTracking();
      
      // Show dialog to user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reset Permissions'),
          content: Text(
            'Permission tracking has been reset. You may need to manually enable permissions in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error resetting permissions: $e');
    }
  }

  bool get _allPermissionsGranted {
    return _permissionStatus.values.every((granted) => granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            children: [



              // Title
              Text(
                'Permissions Required',
                style: AppTypography.headlineLarge.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 12,
                  desktop: 16,
                ),
              ),
              // Subtitle
              Text(
                'We need these permissions to provide you with the best experience',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: ResponsiveUtils.responsiveSpacing(
                  context,
                  mobile: 32,
                  tablet: 40,
                  desktop: 48,
                ),
              ),
              // Permissions List
              Expanded(
                child: ListView.builder(
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permission = _permissions[index];
                    final isGranted = _permissionStatus[permission.permission] ?? false;
                    
                    return _buildPermissionCard(permission, isGranted);
                  },
                ),
              ),
              // Buttons Section
              Column(
                children: [
                  // Grant All Permissions Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestAllPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 12,
                              tablet: 16,
                              desktop: 20,
                            ),
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28,
                              ),
                              width: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28,
                              ),
                              child: CircularProgressIndicator(
                                color: AppColors.textWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Grant All Permissions',
                              style: AppTypography.bodyLarge.copyWith(
                                fontSize: ResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                  ),
                  // Skip Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _proceedToApp,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(
                          color: AppColors.borderColor,
                          width: 1,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.responsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.responsiveSpacing(
                              context,
                              mobile: 12,
                              tablet: 16,
                              desktop: 20,
                            ),
                          ),
                        ),
                      ),
                      child: Text(
                        'Skip for Now',
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                  ),


                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PermissionItem permission, bool isGranted) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveSpacing(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        border: Border.all(
          color: isGranted ? AppColors.successColor : AppColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: ResponsiveUtils.responsivePadding(context),
        leading: Container(
          width: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 50,
            tablet: 55,
            desktop: 60,
          ),
          height: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 50,
            tablet: 55,
            desktop: 60,
          ),
          decoration: BoxDecoration(
            color: isGranted 
                ? AppColors.successColor.withOpacity(0.1)
                : permission.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 25,
                tablet: 27,
                desktop: 30,
              ),
            ),
          ),
          child: Icon(
            isGranted ? Icons.check_circle : permission.icon,
            color: isGranted ? AppColors.successColor : permission.color,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 24,
              tablet: 26,
              desktop: 28,
            ),
          ),
        ),
        title: Text(
          permission.title,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          permission.description,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
            color: AppColors.textSecondary,
          ),
        ),
        trailing: isGranted
            ? Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 12,
                    desktop: 16,
                  ),
                  vertical: ResponsiveUtils.responsiveSpacing(
                    context,
                    mobile: 4,
                    tablet: 6,
                    desktop: 8,
                  ),
                ),
                decoration: BoxDecoration(
                  color: AppColors.successColor,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                  ),
                ),
                child: Text(
                  'Granted',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 10,
                      tablet: 12,
                      desktop: 14,
                    ),
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : TextButton(
                onPressed: _isLoading ? null : () => _requestPermission(permission),
                child: Text(
                  'Grant',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: permission.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}

class PermissionItem {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  PermissionItem({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
} 