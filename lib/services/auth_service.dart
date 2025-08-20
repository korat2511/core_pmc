import '../models/user_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import '../core/utils/snackbar_utils.dart';

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
    await LocalStorageService.saveUser(user);
    _currentUser = user;
  }

  // Check if user is active
  static bool isUserActive() {
    return _currentUser?.isActive ?? false;
  }
}
