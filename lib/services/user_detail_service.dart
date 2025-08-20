import '../models/user_model.dart';
import '../models/user_detail_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';

class UserDetailService {
  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
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
}
