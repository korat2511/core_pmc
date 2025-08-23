class MaterialCategoryModel {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  MaterialCategoryModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory MaterialCategoryModel.fromJson(Map<String, dynamic> json) {
    return MaterialCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}

class MaterialCategoryResponse {
  final int status;
  final List<MaterialCategoryModel> data;

  MaterialCategoryResponse({
    required this.status,
    required this.data,
  });

  factory MaterialCategoryResponse.fromJson(Map<String, dynamic> json) {
    return MaterialCategoryResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => MaterialCategoryModel.fromJson(item))
          .toList() ?? [],
    );
  }
}

class MaterialCategoryCreateResponse {
  final int status;
  final MaterialCategoryModel data;

  MaterialCategoryCreateResponse({
    required this.status,
    required this.data,
  });

  factory MaterialCategoryCreateResponse.fromJson(Map<String, dynamic> json) {
    return MaterialCategoryCreateResponse(
      status: json['status'] ?? 0,
      data: MaterialCategoryModel.fromJson(json['data'] ?? {}),
    );
  }
}
