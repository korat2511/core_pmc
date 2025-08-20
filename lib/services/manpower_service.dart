import '../models/manpower_model.dart';
import '../models/manpower_response.dart';
import '../models/manpower_entry_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class ManpowerService {
  List<ManpowerModel> _manpowerList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<ManpowerModel> get manpowerList => _manpowerList;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Get manpower by date
  Future<bool> getManpowerByDate({
    required int siteId,
    required String date,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        return false;
      }

      final response = await ApiService.getManpower(
        apiToken: apiToken,
        siteId: siteId,
        date: date,
      );

      if (response.isSuccess) {
        _manpowerList = response.data;
        _isLoading = false;
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load manpower: $e';
      _isLoading = false;
      return false;
    }
  }

  // Save manpower
  Future<bool> saveManpower({
    required int siteId,
    required String date,
    required List<ManpowerEntryModel> entries,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';

      final String? apiToken = await LocalStorageService.getToken();
      if (apiToken == null) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        return false;
      }

      // Convert entries to JSON format
      final List<Map<String, dynamic>> data = entries.map((entry) => entry.toJson()).toList();

      final response = await ApiService.saveManpower(
        apiToken: apiToken,
        siteId: siteId,
        date: date,
        data: data,
      );

      if (response.isSuccess) {
        _manpowerList = response.data;
        _isLoading = false;
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to save manpower: $e';
      _isLoading = false;
      return false;
    }
  }

  // Add entry to local list
  void addEntry(ManpowerEntryModel entry) {
    // This is for local management before saving
    // The actual saving happens through the API
  }

  // Remove entry from local list
  void removeEntry(int index) {
    if (index >= 0 && index < _manpowerList.length) {
      _manpowerList.removeAt(index);
    }
  }

  // Update entry in local list
  void updateEntry(int index, ManpowerEntryModel entry) {
    if (index >= 0 && index < _manpowerList.length) {
      // Update the local list
      // This will be saved when user calls save
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
  }

  // Clear manpower list
  void clearManpowerList() {
    _manpowerList.clear();
  }
}
