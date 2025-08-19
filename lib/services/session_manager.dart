import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';
import '../core/utils/snackbar_utils.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static SessionManager get instance => _instance;

  // Handle session expiration
  static Future<void> handleSessionExpired(BuildContext context) async {
    // Clear all login data
    await AuthService.logout();
    
    // Show session expired message
    if (context.mounted) {
      SnackBarUtils.showError(
        context,
        message: 'Session expired. Please login again.',
      );
      
      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false, // This removes all previous routes
      );
    }
  }

  // Check if response indicates session expiration
  static bool isSessionExpired(dynamic response) {
    if (response is Map<String, dynamic>) {
      // Check for specific session expired messages
      final message = response['message']?.toString().toLowerCase() ?? '';
      return message.contains('session expired') ||
             message.contains('unauthorized') ||
             message.contains('token expired') ||
             message.contains('invalid auth');
    }
    
    if (response is String) {
      final message = response.toLowerCase();
      return message.contains('session expired') ||
             message.contains('unauthorized') ||
             message.contains('token expired') ||
             message.contains('invalid auth');
    }
    
    return false;
  }

  // Validate current session
  static bool isSessionValid() {
    return AuthService.isLoggedIn() && 
           AuthService.currentToken != null && 
           AuthService.currentUser != null;
  }

  // Clear session data
  static Future<void> clearSession() async {
    await AuthService.logout();
  }
}
