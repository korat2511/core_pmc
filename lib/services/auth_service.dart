import '../models/user_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'permission_service.dart';
import 'site_service.dart';
import 'company_notifier.dart';

class AuthService {
  static UserModel? _currentUser;
  static String? _currentToken;

  // Get current user
  static UserModel? get currentUser => _currentUser;

  static String? get currentToken => _currentToken;

  // Initialize auth service
  static Future<void> init() async {
    await LocalStorageService.init();
    _loadUserFromStorage();
  }

  // Load user from local storage
  static void _loadUserFromStorage() {
    _currentUser = LocalStorageService.getUser();
    _currentToken = LocalStorageService.getToken();
  }

  // Login method
  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await ApiService.login(
        mobile: mobile,
        password: password,
      );

      if (response.isSuccess &&
          response.user != null &&
          response.token != null) {
        // Save user data to local storage
        await LocalStorageService.saveLoginData(
          response.user!,
          response.token!,
        );

        // Update current user and token
        _currentUser = response.user;
        _currentToken = response.token;

        // Initialize permissions from login response
        PermissionService.setPermissions(response.permissions);

        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': response.message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  // Logout method
  static Future<void> logout() async {
    await LocalStorageService.clearAll();
    _currentUser = null;
    _currentToken = null;
    PermissionService.clearPermissions();
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return LocalStorageService.isValidUser();
  }

  // Get user from storage and update current user
  static void refreshUser() {
    _loadUserFromStorage();
  }

  // Update user data
  static Future<void> updateUser(UserModel user) async {
    final currentAllowed = _currentUser?.allowedCompanies;
    final needsAllowedMerge = (user.allowedCompanies == null || user.allowedCompanies!.isEmpty) &&
        (currentAllowed != null && currentAllowed.isNotEmpty);

    final mergedUser = needsAllowedMerge
        ? UserModel.fromJson({
            ...user.toJson(),
            'allowed_companies': currentAllowed.map((company) => company.toJson()).toList(),
          })
        : user;

    await LocalStorageService.saveUser(mergedUser);
    _currentUser = mergedUser;
  }

  // Check if user is active
  static bool isUserActive() {
    return _currentUser?.isActive ?? false;
  }

  // Switch company
  static Future<Map<String, dynamic>> switchCompany(int companyId) async {
    if (_currentToken == null || _currentUser == null) {
      return {'success': false, 'message': 'Not logged in'};
    }

    try {
      // Clear cached site data before switching
      SiteService.clearSites();
      
      final response = await ApiService.switchCompany(
        apiToken: _currentToken!,
        companyId: companyId,
      );

      if (response['status'] == 1) {
        // Update user data with new company info
        if (response['user'] != null) {
          final userData = Map<String, dynamic>.from(response['user']);
          // Add allowed_companies to user data if it exists at top level
          if (response['allowed_companies'] != null) {
            userData['allowed_companies'] = response['allowed_companies'];
          }
          final updatedUser = UserModel.fromJson(userData);
          await updateUser(updatedUser);
        }

        // Update permissions for new company
        if (response['permissions'] != null) {
          PermissionService.setPermissions(response['permissions']);
        }

        // Notify all listeners that company has changed
        CompanyNotifier.notifyCompanyChanged();

        return {
          'success': true,
          'message': 'Company switched successfully',
          'companyName': response['company_name']
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to switch company'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.'
      };
    }
  }
}
