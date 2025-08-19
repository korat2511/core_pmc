class SiteUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final int userType;
  final String? deviceId;
  final String status;
  final String? image;
  final String? siteId;
  final String createdAt;
  final String updatedAt;
  final String? imageUrl;

  SiteUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.userType,
    this.deviceId,
    required this.status,
    this.image,
    this.siteId,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  factory SiteUserModel.fromJson(Map<String, dynamic> json) {
    return SiteUserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 0,
      deviceId: json['device_id'],
      status: json['status'] ?? '',
      image: json['image'],
      siteId: json['site_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'mobile': mobile,
      'email': email,
      'user_type': userType,
      'device_id': deviceId,
      'status': status,
      'image': image,
      'site_id': siteId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image_url': imageUrl,
    };
  }

  // Helper getters
  String get fullName => '$firstName $lastName';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isActive => status.toLowerCase() == 'active';
  List<int> get siteIds {
    if (siteId == null || siteId!.isEmpty) return [];
    return siteId!.split(',').map((id) => int.tryParse(id.trim()) ?? 0).where((id) => id > 0).toList();
  }
}
