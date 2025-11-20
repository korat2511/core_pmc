import 'user_model.dart';

class ApiResponse<T> {
  final int status;
  final String message;
  final T? data;
  final String? token;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.token,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJson) {
    try {
      return ApiResponse(
        status: json['status'] is int ? json['status'] : (json['status'] is String ? int.tryParse(json['status']) ?? 0 : 0),
        message: json['message']?.toString() ?? '',
        data: json['data'] != null && fromJson != null ? fromJson(json['data'] as Map<String, dynamic>) : null,
        token: json['token']?.toString(),
      );
    } catch (e) {
      // Fallback if parsing fails
      return ApiResponse(
        status: 0,
        message: 'Failed to parse response: ${e.toString()}',
        data: null,
        token: null,
      );
    }
  }

  bool get isSuccess {
    return status == 1;
  }
  bool get isError => status != 1;
}

class LoginResponse {
  final int status;
  final String message;
  final String? token;
  final UserModel? user;
  final Map<String, dynamic>? permissions;

  LoginResponse({
    required this.status,
    required this.message,
    this.token,
    this.user,
    this.permissions,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] ?? 0;
    final message = json['message'] ?? '';
    final token = json['token'];
    
    // Merge user data with allowed_companies from top level
    UserModel? user;
    if (json['data'] != null) {
      final userData = Map<String, dynamic>.from(json['data']);
      // Add allowed_companies to user data if it exists at top level
      if (json['allowed_companies'] != null) {
        userData['allowed_companies'] = json['allowed_companies'];
      }
      user = UserModel.fromJson(userData);
    }
    
    // Handle permissions - can be either a List (empty array) or Map
    Map<String, dynamic>? permissions;
    if (json['permissions'] != null) {
      if (json['permissions'] is Map) {
        permissions = json['permissions'] as Map<String, dynamic>;
      } else if (json['permissions'] is List) {
        // If permissions is a List (empty array), set to null or empty map
        permissions = null;
      }
    }
    
    return LoginResponse(
      status: status,
      message: message,
      token: token,
      user: user,
      permissions: permissions,
    );
  }

  bool get isSuccess => status == 1;
  bool get isError => status != 1;
} 