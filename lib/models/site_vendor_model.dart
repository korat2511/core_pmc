import '../models/category_model.dart';

class SiteVendorModel {
  final int id;
  final int siteId;
  final String? categoryName;
  final int categoryId;
  final String name;
  final String mobile;
  final String email;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final CategoryModel? category;

  SiteVendorModel({
    required this.id,
    required this.siteId,
    this.categoryName,
    required this.categoryId,
    required this.name,
    required this.mobile,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.category,
  });

  factory SiteVendorModel.fromJson(Map<String, dynamic> json) {
    return SiteVendorModel(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      categoryName: json['category_name'],
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      category: json['category'] != null 
          ? CategoryModel.fromJson(json['category']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'category_name': categoryName,
      'category_id': categoryId,
      'name': name,
      'mobile': mobile,
      'email': email,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'category': category?.toJson(),
    };
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
          .toList() ?? [],
    );
  }
}
