import 'package:flutter/material.dart';
import '../models/version_model.dart';
import '../services/version_check_service.dart';
import '../widgets/force_update_dialog.dart';

class ForceUpdateManager {
  static bool _isChecking = false;
  static bool _hasShownDialog = false;

  static Future<void> checkForUpdates(BuildContext context) async {
    if (_isChecking || _hasShownDialog) return;
    
    _isChecking = true;
    
    try {
      // Get current version
      final currentVersion = await VersionCheckService.getCurrentVersion();
      
      // Check for updates
      final versionData = await VersionCheckService.checkForUpdates();
      
      if (versionData != null) {
        final isUpdateRequired = VersionCheckService.isUpdateRequired(
          currentVersion,
          versionData.latestVersion,
        );
        
        if (isUpdateRequired) {
          _hasShownDialog = true;
          _showUpdateDialog(
            context,
            versionData,
            currentVersion,
            versionData.forceUpdate,
          );
        }
      }
    } catch (e) {
      print('Error in force update check: $e');
    } finally {
      _isChecking = false;
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    VersionModel versionData,
    String currentVersion,
    bool isForceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => ForceUpdateDialog(
        versionData: versionData,
        currentVersion: currentVersion,
        isForceUpdate: isForceUpdate,
      ),
    );
  }

  static void reset() {
    _hasShownDialog = false;
    _isChecking = false;
  }

  // Method to manually trigger update check
  static Future<void> manualUpdateCheck(BuildContext context) async {
    _hasShownDialog = false;
    await checkForUpdates(context);
  }
}
