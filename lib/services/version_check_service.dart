import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_model.dart';

class VersionCheckService {
  static const String _versionJsonUrl = 'https://raw.githubusercontent.com/korat2511/pmc_version_json/main/version.json';
  
  static Future<VersionModel?> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(_versionJsonUrl));




      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return VersionModel.fromJson(jsonData);
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Error getting current version: $e');
      return '1.0.0';
    }
  }

  static bool isUpdateRequired(String currentVersion, String latestVersion) {
    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    // Pad with zeros to make equal length
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);
    
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    return 0;
  }

  static Future<void> openUpdateUrl(VersionModel versionData) async {
    String url;
    
    if (Platform.isAndroid) {
      // Try Play Store first, then Google Drive, then fallback URL
      url = versionData.androidPlayStoreUrl ?? 
            versionData.androidGoogleDriveUrl ?? 
            versionData.androidUpdateUrl;
    } else if (Platform.isIOS) {
      // Try App Store first, then TestFlight, then fallback URL
      url = versionData.iosAppStoreUrl ?? 
            versionData.iosTestFlightUrl ?? 
            versionData.iosUpdateUrl;
    } else {
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening update URL: $e');
    }
  }
}

