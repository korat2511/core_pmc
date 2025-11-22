class CategoryModel {
  final int id;
  final String name;
  final int siteId;
  final int catSubId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final Map<String, dynamic>? company;

  CategoryModel({
    required this.id,
    required this.name,
    required this.siteId,
    required this.catSubId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.company,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      siteId: json['site_id'] is int ? json['site_id'] : int.tryParse(json['site_id'].toString()) ?? 0,
      catSubId: json['cat_sub_id'] is int ? json['cat_sub_id'] : int.tryParse(json['cat_sub_id'].toString()) ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
      company: json['company'] != null && json['company'] is Map 
          ? Map<String, dynamic>.from(json['company']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'site_id': siteId,
      'cat_sub_id': catSubId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'company': company,
    };
  }

  // Helper getters
  bool get isEditable => ![1, 2, 3, 4, 6].contains(catSubId);
  bool get isDeletable => ![1, 2, 3, 4, 6].contains(catSubId);
  bool get isActive => deletedAt == null;
}
