import 'site_user_model.dart';

class SiteUserResponse {
  final int status;
  final String message;
  final List<SiteUserModel> users;

  SiteUserResponse({
    required this.status,
    required this.message,
    required this.users,
  });

  factory SiteUserResponse.fromJson(Map<String, dynamic> json) {
    List<SiteUserModel> users = [];
    
    // Handle both single user and list of users
    if (json['user'] != null) {
      if (json['user'] is List) {
        // Multiple users
        users = (json['user'] as List<dynamic>)
            .map((user) => SiteUserModel.fromJson(user))
            .toList();
      } else if (json['user'] is Map<String, dynamic>) {
        // Single user
        users = [SiteUserModel.fromJson(json['user'])];
      }
    }
    
    return SiteUserResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      users: users,
    );
  }

  bool get isSuccess => status == 1;
}
