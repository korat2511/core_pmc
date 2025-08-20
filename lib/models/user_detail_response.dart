import 'user_model.dart';

class UserDetailResponse {
  final int status;
  final String message;
  final UserModel? user;

  UserDetailResponse({
    required this.status,
    required this.message,
    this.user,
  });

  factory UserDetailResponse.fromJson(Map<String, dynamic> json) {
    return UserDetailResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'user': user?.toJson(),
    };
  }

  bool get isSuccess => status == 1;
}
