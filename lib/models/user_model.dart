class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? deviceId;
  final String mobile;
  final String email;
  final int userType;
  final String status;
  final int? siteId;
  final String? image;
  final String lastActiveTime;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? imageUrl;
  final String apiToken;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.deviceId,
    required this.mobile,
    required this.email,
    required this.userType,
    required this.status,
    this.siteId,
    this.image,
    required this.lastActiveTime,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.imageUrl,
    required this.apiToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      deviceId: json['device_id'],
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 0,
      status: json['status'] ?? '',
      siteId: json['site_id'] is int ? json['site_id'] : null,
      image: json['image'],
      lastActiveTime: json['last_active_time']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at'],
      imageUrl: json['image_url'],
      apiToken: json['api_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'device_id': deviceId,
      'mobile': mobile,
      'email': email,
      'user_type': userType,
      'status': status,
      'site_id': siteId,
      'image': image,
      'last_active_time': lastActiveTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image_url': imageUrl,
      'api_token': apiToken,
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  String get displayName => fullName.isNotEmpty ? fullName : email;

  bool get isActive => status.toLowerCase() == 'active';
}
