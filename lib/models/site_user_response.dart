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
    return SiteUserResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      users: (json['user'] as List<dynamic>?)
              ?.map((user) => SiteUserModel.fromJson(user))
              .toList() ??
          [],
    );
  }

  bool get isSuccess => status == 1;
}
