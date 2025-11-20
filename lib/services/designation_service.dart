import '../models/designation_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DesignationService {
  static final List<DesignationModel> _designations = [];
  static bool _isLoading = false;
  static String _errorMessage = '';

  static List<DesignationModel> get designations =>
      List.unmodifiable(_designations);

  static bool get isLoading => _isLoading;

  static String get errorMessage => _errorMessage;

  static void clear() {
    _designations.clear();
    _errorMessage = '';
  }

  static Future<bool> loadDesignations({required int companyId}) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      _errorMessage = 'Session expired. Please log in again.';
      return false;
    }

    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      return false;
    }

    _isLoading = true;
    _errorMessage = '';

    final response = await ApiService.getDesignations(
      apiToken: token,
      companyId: companyId,
    );

    _isLoading = false;

    if (response['status'] == 1 && response['data'] != null) {
      _designations
        ..clear()
        ..addAll((response['data'] as List<dynamic>)
            .map((d) => DesignationModel.fromJson(d)));
      _designations.sort((a, b) => a.order.compareTo(b.order));
      return true;
    }

    _errorMessage = response['message'] ?? 'Failed to load designations';
    return false;
  }

  static Future<DesignationModel?> createDesignation({
    required int companyId,
    required String name,
    int? order,
    String status = 'active',
  }) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      return null;
    }

    final response = await ApiService.createDesignation(
      apiToken: token,
      companyId: companyId,
      name: name,
      order: order,
      status: status,
    );

    if (response['status'] == 1 && response['data'] != null) {
      final designation = DesignationModel.fromJson(response['data']);
      _designations.add(designation);
      _designations.sort((a, b) => a.order.compareTo(b.order));
      return designation;
    }

    _errorMessage = response['message'] ?? 'Failed to create designation';
    return null;
  }

  static Future<DesignationModel?> updateDesignation({
    required int designationId,
    String? name,
    int? order,
    String? status,
  }) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      return null;
    }

    final response = await ApiService.updateDesignation(
      apiToken: token,
      designationId: designationId,
      name: name,
      order: order,
      status: status,
    );

    if (response['status'] == 1 && response['data'] != null) {
      final updated = DesignationModel.fromJson(response['data']);
      final index =
          _designations.indexWhere((designation) => designation.id == updated.id);
      if (index != -1) {
        _designations[index] = updated;
      } else {
        // If not found, add it (shouldn't happen, but handle it)
        _designations.add(updated);
      }
      // Sort by order after update
      _designations.sort((a, b) => a.order.compareTo(b.order));
      return updated;
    }

    _errorMessage = response['message'] ?? 'Failed to update designation';
    return null;
  }

  static Future<bool> deleteDesignation({required int designationId}) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      return false;
    }

    final response = await ApiService.deleteDesignation(
      apiToken: token,
      designationId: designationId,
    );

    if (response['status'] == 1) {
      _designations
          .removeWhere((designation) => designation.id == designationId);
      return true;
    }

    _errorMessage = response['message'] ?? 'Failed to delete designation';
    return false;
  }

  static Future<bool> reorderDesignations({
    required int companyId,
    required List<DesignationModel> orderedDesignations,
  }) async {
    _designations
      ..clear()
      ..addAll(orderedDesignations);
    _designations.sort((a, b) => a.order.compareTo(b.order));

    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      return false;
    }

    final payload = orderedDesignations
        .asMap()
        .entries
        .map(
          (entry) => {
            'id': entry.value.id,
            'order': entry.key,
          },
        )
        .toList();

    final response = await ApiService.reorderDesignations(
      apiToken: token,
      companyId: companyId,
      designations: payload,
    );

    if (response['status'] == 1 && response['data'] != null) {
      _designations
        ..clear()
        ..addAll((response['data'] as List<dynamic>)
            .map((d) => DesignationModel.fromJson(d)));
      _designations.sort((a, b) => a.order.compareTo(b.order));
      return true;
    }

    _errorMessage = response['message'] ?? 'Failed to reorder designations';
    return false;
  }

  static Future<Map<String, dynamic>?> getDesignationAccess({
    required int designationId,
  }) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      return null;
    }

    final response = await ApiService.getDesignationAccess(
      apiToken: token,
      designationId: designationId,
    );

    if (response['status'] == 1) {
      return response['data'] as Map<String, dynamic>?;
    }

    _errorMessage =
        response['message'] ?? 'Failed to fetch designation permissions';
    return null;
  }

  static Future<bool> updateDesignationAccess({
    required int designationId,
    required Map<String, dynamic> permissions,
  }) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      return false;
    }

    final response = await ApiService.updateDesignationAccess(
      apiToken: token,
      designationId: designationId,
      permissions: permissions,
    );

    if (response['status'] == 1) {
      return true;
    }

    _errorMessage =
        response['message'] ?? 'Failed to update designation permissions';
    return false;
  }
}


