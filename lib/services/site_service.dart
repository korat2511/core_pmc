import '../models/site_model.dart';
import '../models/site_list_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'auth_service.dart';
import 'session_manager.dart';

class SiteService {
  static List<SiteModel> _allSites = [];
  static List<SiteModel> _sites = [];
  static bool _isLoading = false;
  static String _errorMessage = '';

  // Getters
  static List<SiteModel> get sites => _sites;
  static List<SiteModel> get allSites => _allSites;
  static bool get isLoading => _isLoading;
  static String get errorMessage => _errorMessage;
  static bool get hasError => _errorMessage.isNotEmpty;

  // Get site list from API
  static Future<bool> getSiteList({String status = ''}) async {
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
      final SiteListResponse response = await ApiService.getSiteList(
        apiToken: apiToken,
        status: status,
      );

      if (response.isSuccess) {
        _allSites = response.data;
        
        // Sort sites: pinned sites first, then by name
        _allSites.sort((a, b) {
          // First, sort by pin status (pinned sites first)
          if (a.isPinned == 1 && b.isPinned != 1) return -1;
          if (a.isPinned != 1 && b.isPinned == 1) return 1;
          
          // If both have same pin status, sort by name
          return a.name.compareTo(b.name);
        });
        
        _sites = _allSites;
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

  // Get sites by status
  static List<SiteModel> getSitesByStatus(String status) {
    if (status.isEmpty) return _allSites;
    return _allSites.where((site) => site.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Get pinned sites
  static List<SiteModel> getPinnedSites() {
    return _allSites.where((site) => site.isPinned == 1).toList();
  }

  // Get active sites
  static List<SiteModel> getActiveSites() {
    return _allSites.where((site) => site.isActive).toList();
  }

  // Get pending sites
  static List<SiteModel> getPendingSites() {
    return _allSites.where((site) => site.isPending).toList();
  }

  // Get complete sites
  static List<SiteModel> getCompleteSites() {
    return _allSites.where((site) => site.isComplete).toList();
  }

  // Get overdue sites
  static List<SiteModel> getOverdueSites() {
    return _allSites.where((site) => site.isOverdue).toList();
  }

  // Clear error message
  static void clearError() {
    _errorMessage = '';
  }

  // Clear sites
  static void clearSites() {
    _allSites.clear();
    _sites.clear();
  }

            // Update filtered sites based on status
          static void updateFilteredSites(String status) {
            List<SiteModel> filteredSites;
            
            if (status.isEmpty) {
              filteredSites = _allSites;
            } else {
              filteredSites = _allSites.where((site) => site.status.toLowerCase() == status.toLowerCase()).toList();
            }
            
            // Sort sites: pinned sites first, then by name
            filteredSites.sort((a, b) {
              // First, sort by pin status (pinned sites first)
              if (a.isPinned == 1 && b.isPinned != 1) return -1;
              if (a.isPinned != 1 && b.isPinned == 1) return 1;
              
              // If both have same pin status, sort by name
              return a.name.compareTo(b.name);
            });
            
            _sites = filteredSites;
          }

          // Update a specific site in the list
          static void updateSite(SiteModel updatedSite) {
            // Update in all sites list
            final allSitesIndex = _allSites.indexWhere((site) => site.id == updatedSite.id);
            if (allSitesIndex != -1) {
              _allSites[allSitesIndex] = updatedSite;
            }

            // Update in filtered sites list
            final filteredSitesIndex = _sites.indexWhere((site) => site.id == updatedSite.id);
            if (filteredSitesIndex != -1) {
              _sites[filteredSitesIndex] = updatedSite;
            }
          }

          // Pin/Unpin Site
          static Future<bool> pinSite(int siteId, {String currentStatus = ''}) async {
            try {
              final user = AuthService.currentUser;
              if (user == null) {
                _errorMessage = 'User not logged in';
                return false;
              }

              final result = await ApiService.pinSite(
                apiToken: user.apiToken,
                siteId: siteId,
              );

              if (result['success']) {
                // Update the site's pin status locally
                final siteIndex = _allSites.indexWhere((site) => site.id == siteId);
                if (siteIndex != -1) {
                  final currentSite = _allSites[siteIndex];
                  final updatedSite = currentSite.copyWith(
                    isPinned: currentSite.isPinned == 1 ? 0 : 1,
                  );
                  _allSites[siteIndex] = updatedSite;

                  // Re-sort all sites after pin status change
                  _allSites.sort((a, b) {
                    // First, sort by pin status (pinned sites first)
                    if (a.isPinned == 1 && b.isPinned != 1) return -1;
                    if (a.isPinned != 1 && b.isPinned == 1) return 1;
                    
                    // If both have same pin status, sort by name
                    return a.name.compareTo(b.name);
                  });

                  // Re-apply current filter and sorting
                  updateFilteredSites(currentStatus);
                }
                return true;
              } else {
                _errorMessage = result['message'] ?? 'Failed to pin/unpin site';
                return false;
              }
            } catch (e) {
              _errorMessage = 'Error pinning/unpinning site: $e';
              return false;
            }
          }
} 