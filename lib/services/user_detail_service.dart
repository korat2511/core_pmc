import 'dart:io';
import '../models/user_model.dart';
import '../models/user_detail_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';
import 'auth_service.dart';

class UserDetailService {
  UserModel? _user;
  bool _isLoading = false;
  bool _isUpdating = false;
  String _errorMessage = '';

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Get user details by ID
  Future<bool> getUserDetails(int userId) async {
    try {
      _isLoading = true;
      _errorMessage = '';

      // Get API token from local storage
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isLoading = false;
        return false;
      }

      // Call API
      final UserDetailResponse response = await ApiService.getUserFromId(
        apiToken: apiToken,
        userId: userId,
      );

      if (response.isSuccess) {
        _user = response.user;
        _isLoading = false;
        return true;
      } else {
        // Check for session expiration
        if (response.status == 401 || SessionManager.isSessionExpired(response.message)) {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
          return false;
        }
        
        _errorMessage = response.message;
        _isLoading = false;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load user details: $e';
      _isLoading = false;
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
  }

  // Clear user data
  void clearUser() {
    _user = null;
  }

  Future<bool> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? status,
    int? designationId,
    File? image,
  }) async {
    try {
      _isUpdating = true;
      _errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isUpdating = false;
        return false;
      }

      final response = await ApiService.updateUser(
        apiToken: apiToken,
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobile: mobile,
        status: status,
        designationId: designationId,
        image: image,
      );

      if ((response['status'] ?? 0) == 1) {
        if (response['user'] is Map) {
          final responseMap = Map<String, dynamic>.from(response['user'] as Map);

          // Ensure allowed_companies is present; fall back to existing data if missing
          if (!responseMap.containsKey('allowed_companies') ||
              responseMap['allowed_companies'] == null) {
            final cachedAllowed = AuthService.currentUser?.allowedCompanies;
            if (cachedAllowed != null) {
              responseMap['allowed_companies'] =
                  cachedAllowed.map((company) => company.toJson()).toList();
            }
          }

          final updatedUser = UserModel.fromJson(responseMap);
          _user = updatedUser;

          if (AuthService.currentUser?.id == updatedUser.id) {
            await AuthService.updateUser(updatedUser);
          }
        }

        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Failed to update user';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update user: $e';
      return false;
    } finally {
      _isUpdating = false;
    }
  }
}
