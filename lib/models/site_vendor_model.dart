class SiteVendorModel {
  final int id;
  final int siteId;
  final String? gstNo;
  final String name;
  final String mobile;
  final String email;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  SiteVendorModel({
    required this.id,
    required this.siteId,
    this.gstNo,
    required this.name,
    required this.mobile,
    required this.email,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SiteVendorModel.fromJson(Map<String, dynamic> json) {
    return SiteVendorModel(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      gstNo: json['gst_no'],
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'gst_no': gstNo,
      'name': name,
      'mobile': mobile,
      'email': email,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  SiteVendorModel copyWith({
    int? id,
    int? siteId,
    String? gstNo,
    String? name,
    String? mobile,
    String? email,
    String? deletedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return SiteVendorModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      gstNo: gstNo ?? this.gstNo,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SiteVendorResponse {
  final String status;
  final String message;
  final List<SiteVendorModel> data;

  SiteVendorResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SiteVendorResponse.fromJson(Map<String, dynamic> json) {
    return SiteVendorResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => SiteVendorModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
