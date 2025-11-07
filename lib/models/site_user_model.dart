class SiteUserDesignation {
  final int id;
  final String name;
  final int order;

  SiteUserDesignation({
    required this.id,
    required this.name,
    required this.order,
  });

  factory SiteUserDesignation.fromJson(Map<String, dynamic> json) {
    return SiteUserDesignation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class SiteUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final int? designationId;
  final SiteUserDesignation? designation;
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
    this.designationId,
    this.designation,
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
      designationId: json['designation_id'],
      designation: json['designation_relation'] != null
          ? SiteUserDesignation.fromJson(json['designation_relation'])
          : null,
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
      'designation_id': designationId,
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
  String get designationName => designation?.name ?? 'Employee';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isActive => status.toLowerCase() == 'active';
  List<int> get siteIds {
    if (siteId == null || siteId!.isEmpty) return [];
    return siteId!.split(',').map((id) => int.tryParse(id.trim()) ?? 0).where((id) => id > 0).toList();
  }
}
