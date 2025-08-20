import '../models/qc_category_model.dart';
import '../models/qc_category_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class QcCategoryService {
  List<QcCategoryModel> _qcCategories = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<QcCategoryModel> get qcCategories => _qcCategories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Get QC Categories
  Future<bool> getQcCategories({int page = 1}) async {
    try {
      _isLoading = true;
      _errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        return false;
      }

      final response = await ApiService.getQcCategories(
        apiToken: apiToken,
        page: page,
      );

      if (response.isSuccess) {
        _qcCategories = response.points;
        _isLoading = false;
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load QC categories: $e';
      _isLoading = false;
      return false;
    }
  }

  // Create QC Category
  Future<bool> createQcCategory(String name) async {
    try {
      _errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found';
        return false;
      }

      final response = await ApiService.createQcCategory(
        apiToken: apiToken,
        name: name,
      );

      if (response.isSuccess) {
        // Refresh the list after creating
        return await getQcCategories();
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create QC category: $e';
      return false;
    }
  }
}
