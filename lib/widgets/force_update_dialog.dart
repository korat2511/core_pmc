import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_model.dart';
import '../services/version_check_service.dart';

class ForceUpdateDialog extends StatelessWidget {
  final VersionModel versionData;
  final String currentVersion;
  final bool isForceUpdate;

  const ForceUpdateDialog({
    Key? key,
    required this.versionData,
    required this.currentVersion,
    this.isForceUpdate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForceUpdate, // Prevent back button if force update
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of the app is available.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            _buildVersionInfo(),
            SizedBox(height: 16),
            if (isForceUpdate) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required to continue using the app.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            _buildDownloadOptions(context),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Later'),
            ),
          ElevatedButton(
            onPressed: () => _handleUpdate(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Version:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(currentVersion, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Latest Version:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                versionData.latestVersion,
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download Options:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        if (Platform.isAndroid) ...[
          if (versionData.androidPlayStoreUrl != null)
            _buildDownloadOption(
              context,
              'Google Play Store',
              Icons.shop,
              Colors.green,
              () => _launchUrl(versionData.androidPlayStoreUrl!),
            ),
          if (versionData.androidGoogleDriveUrl != null)
            _buildDownloadOption(
              context,
              'Google Drive',
              Icons.cloud_download,
              Colors.blue,
              () => _launchUrl(versionData.androidGoogleDriveUrl!),
            ),
          _buildDownloadOption(
            context,
            'Direct Download',
            Icons.download,
            Colors.orange,
            () => _launchUrl(versionData.androidUpdateUrl),
          ),
        ] else if (Platform.isIOS) ...[
          if (versionData.iosAppStoreUrl != null)
            _buildDownloadOption(
              context,
              'App Store',
              Icons.shop,
              Colors.blue,
              () => _launchUrl(versionData.iosAppStoreUrl!),
            ),
          if (versionData.iosTestFlightUrl != null)
            _buildDownloadOption(
              context,
              'TestFlight',
              Icons.flight_takeoff,
              Colors.purple,
              () => _launchUrl(versionData.iosTestFlightUrl!),
            ),
          _buildDownloadOption(
            context,
            'Direct Download',
            Icons.download,
            Colors.orange,
            () => _launchUrl(versionData.iosUpdateUrl),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUpdate(BuildContext context) {
    VersionCheckService.openUpdateUrl(versionData);
    if (!isForceUpdate) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
