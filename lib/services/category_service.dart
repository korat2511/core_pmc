import '../models/category_model.dart';
import '../models/category_response.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class CategoryService {
  List<CategoryModel> categories = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<bool> getCategoriesBySite({
    required int siteId,
  }) async {
    try {
      isLoading = true;
      errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        errorMessage = 'Authentication token not found';
        isLoading = false;
        return false;
      }

      final response = await ApiService.getCategoriesBySite(
        apiToken: apiToken,
        siteId: siteId,
      );

      if (response.isSuccess) {
        categories = response.categories;
        isLoading = false;
        return true;
      } else {
        errorMessage = response.message;
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to load categories: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> createCategory({
    required int siteId,
    required String name,
  }) async {
    try {
      isLoading = true;
      errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        errorMessage = 'Authentication token not found';
        isLoading = false;
        return false;
      }

      final response = await ApiService.createCategory(
        apiToken: apiToken,
        siteId: siteId,
        name: name,
      );

      if (response.isSuccess) {
        // Refresh the categories list
        await getCategoriesBySite(siteId: siteId);
        isLoading = false;
        return true;
      } else {
        errorMessage = response.message;
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to create category: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> updateCategory({
    required int categoryId,
    required String name,
    required int siteId,
  }) async {
    try {
      isLoading = true;
      errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        errorMessage = 'Authentication token not found';
        isLoading = false;
        return false;
      }

      final response = await ApiService.updateCategory(
        apiToken: apiToken,
        categoryId: categoryId,
        name: name,
        siteId: siteId,
      );

      if (response.isSuccess) {
        // Refresh the categories list
        await getCategoriesBySite(siteId: siteId);
        isLoading = false;
        return true;
      } else {
        errorMessage = response.message;
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to update category: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> deleteCategory({
    required int categoryId,
    required int siteId,
  }) async {
    try {
      isLoading = true;
      errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        errorMessage = 'Authentication token not found';
        isLoading = false;
        return false;
      }

      final response = await ApiService.deleteCategory(
        apiToken: apiToken,
        categoryId: categoryId,
      );

      if (response.isSuccess) {
        // Refresh the categories list
        await getCategoriesBySite(siteId: siteId);
        isLoading = false;
        return true;
      } else {
        errorMessage = response.message;
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to delete category: $e';
      isLoading = false;
      return false;
    }
  }
}
