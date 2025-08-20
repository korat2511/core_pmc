import '../models/site_model.dart';
import '../models/site_list_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';

class UserSitesService {
  List<SiteModel> _sites = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<SiteModel> get sites => _sites;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Get sites by user from API
  Future<bool> getSitesByUser({required int userId}) async {
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
      final SiteListResponse response = await ApiService.getSiteListByUser(
        apiToken: apiToken,
        userId: userId,
      );

      if (response.isSuccess) {
        _sites = response.data;
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
      _errorMessage = 'Failed to load sites: $e';
      _isLoading = false;
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
  }

  // Clear sites
  void clearSites() {
    _sites.clear();
  }
}
