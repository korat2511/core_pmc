class CompanyInfo {
  final int id;
  final String name;
  final String? companyCode;
  final String? email;

  CompanyInfo({
    required this.id,
    required this.name,
    this.companyCode,
    this.email,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      companyCode: json['company_code'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company_code': companyCode,
      'email': email,
    };
  }
}

class DesignationInfo {
  final int id;
  final String name;
  final int order;
  final String status;

  DesignationInfo({
    required this.id,
    required this.name,
    required this.order,
    required this.status,
  });

  factory DesignationInfo.fromJson(Map<String, dynamic> json) {
    return DesignationInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'status': status,
    };
  }

  bool get isAdmin {
    final lowerName = name.toLowerCase();
    return lowerName.contains('admin') ||
        lowerName.contains('owner') ||
        lowerName.contains('director');
  }
}

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? deviceId;
  final String mobile;
  final String email;
  final int? designationId;
  final DesignationInfo? designationInfo;
  final String status;
  final dynamic siteId; // Can be int or String (comma-separated site IDs)
  final String? image;
  final String lastActiveTime;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? imageUrl;
  final String apiToken;
  final CompanyInfo? company;
  final List<CompanyInfo>? allowedCompanies;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.deviceId,
    required this.mobile,
    required this.email,
    this.designationId,
    this.designationInfo,
    required this.status,
    this.siteId,
    this.image,
    required this.lastActiveTime,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.imageUrl,
    required this.apiToken,
    this.company,
    this.allowedCompanies,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      deviceId: json['device_id'],
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      designationId: json['designation_id'],
      designationInfo: json['designation_relation'] != null
          ? DesignationInfo.fromJson(json['designation_relation'])
          : null,
      status: json['status'] ?? '',
      siteId: json['site_id'],
      image: json['image'],
      lastActiveTime: json['last_active_time']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at'],
      imageUrl: json['image_url'],
      apiToken: json['api_token'] ?? '',
      company: json['company'] != null ? CompanyInfo.fromJson(json['company']) : null,
      allowedCompanies: json['allowed_companies'] != null
          ? (json['allowed_companies'] as List<dynamic>)
              .map((c) => CompanyInfo.fromJson(c))
              .toList()
          : null,
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
      'designation_id': designationId,
      'designation_relation': designationInfo?.toJson(),
      'status': status,
      'site_id': siteId,
      'image': image,
      'last_active_time': lastActiveTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image_url': imageUrl,
      'api_token': apiToken,
      'company': company?.toJson(),
      'allowed_companies': allowedCompanies?.map((c) => c.toJson()).toList(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  String get displayName => fullName.isNotEmpty ? fullName : email;

  bool get isActive => status.toLowerCase() == 'active';
  
  // Get designation display name
  String get designationDisplay => designationInfo?.name ?? 'Employee';
  
  // Get company name
  String get companyName => company?.name ?? 'PMC';
  
  // Get company ID
  int? get companyId => company?.id;
  
  // Check if user has multiple companies
  bool get hasMultipleCompanies => (allowedCompanies?.length ?? 0) > 1;
  
  // Check if user is admin based on designation
  bool get isAdmin => designationInfo?.isAdmin ?? false;
  
  // Check if user has admin permission
  bool hasPermission(String permission) {
    // For now, admin has all permissions
    // Can be extended with role-based permissions later
    return isAdmin;
  }
  
  // Get formatted site IDs
  String get formattedSiteIds {
    if (siteId == null) return 'N/A';
    if (siteId is String) return siteId as String;
    if (siteId is int) return siteId.toString();
    return 'N/A';
  }
  
  // Get list of site IDs
  List<String> get siteIdList {
    if (siteId == null) return [];
    if (siteId is String) {
      return (siteId as String).split(',').map((id) => id.trim()).toList();
    }
    if (siteId is int) {
      return [siteId.toString()];
    }
    return [];
  }
}
