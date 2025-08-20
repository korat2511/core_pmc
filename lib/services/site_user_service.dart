import '../models/site_user_model.dart';
import '../models/site_user_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';

class SiteUserService {
  List<SiteUserModel> _users = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<SiteUserModel> get users => _users;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Get users by site from API
  Future<bool> getUsersBySite({
    required int siteId,
  }) async {
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
      final SiteUserResponse response = await ApiService.getUsersBySite(
        apiToken: apiToken,
        siteId: siteId,
      );

      if (response.isSuccess) {
        _users = response.users;
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
      _errorMessage = 'Failed to load users: $e';
      _isLoading = false;
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
  }

  // Clear users
  void clearUsers() {
    _users.clear();
  }
}
