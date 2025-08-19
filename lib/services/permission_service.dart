import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const String _lastPermissionRequestKey = 'last_permission_request';
  static const int _permissionRequestIntervalDays = 3;

  // Check if permission screen should be shown
  static Future<bool> shouldShowPermissionScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestTime = prefs.getString(_lastPermissionRequestKey);
      
      if (lastRequestTime == null) {
        // First time, show permission screen
        return true;
      }

      final lastRequest = DateTime.parse(lastRequestTime);
      final now = DateTime.now();
      final difference = now.difference(lastRequest).inDays;

      // Show permission screen if 3 days have passed
      return difference >= _permissionRequestIntervalDays;
    } catch (e) {
      print('Error checking permission screen status: $e');
      return true; // Show by default if error
    }
  }

  // Mark that permission screen was shown
  static Future<void> markPermissionScreenShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      await prefs.setString(_lastPermissionRequestKey, now);
      print('Permission screen marked as shown at: $now');
    } catch (e) {
      print('Error marking permission screen shown: $e');
    }
  }

  // Reset permission screen tracking (for testing)
  static Future<void> resetPermissionTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastPermissionRequestKey);
      print('Permission tracking reset');
    } catch (e) {
      print('Error resetting permission tracking: $e');
    }
  }

  // Get days since last permission request
  static Future<int> getDaysSinceLastRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestTime = prefs.getString(_lastPermissionRequestKey);
      
      if (lastRequestTime == null) {
        return 999; // Large number to force show
      }

      final lastRequest = DateTime.parse(lastRequestTime);
      final now = DateTime.now();
      return now.difference(lastRequest).inDays;
    } catch (e) {
      print('Error getting days since last request: $e');
      return 999;
    }
  }
} 