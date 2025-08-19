import 'dart:io';
import '../models/api_response.dart';
import '../models/site_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class SiteUpdateService {
  bool _isLoading = false;
  String _errorMessage = '';
  SiteModel? _updatedSite;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  SiteModel? get updatedSite => _updatedSite;

  // Update site details
  Future<bool> updateSite({
    required int siteId,
    String? siteName,
    String? clientName,
    String? architectName,
    String? address,
    double? latitude,
    double? longitude,
    String? startDate,
    String? endDate,
    int? minRange,
    int? maxRange,
    List<File>? images,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      _updatedSite = null;

      // Get API token from local storage
      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isLoading = false;
        return false;
      }

      // Call API
      final ApiResponse response = await ApiService.updateSite(
        apiToken: apiToken,
        siteId: siteId,
        siteName: siteName,
        clientName: clientName,
        architectName: architectName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        startDate: startDate,
        endDate: endDate,
        minRange: minRange,
        maxRange: maxRange,
        images: images,
      );

      if (response.isSuccess) {
        // Parse the updated site data from response
        if (response.data != null) {
          try {
            _updatedSite = SiteModel.fromJson(response.data);
          } catch (e) {
            // If parsing fails, create a basic updated site with the new values
            _updatedSite = null;
          }
        }
        _isLoading = false;
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update site: $e';
      _isLoading = false;
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
  }
}
