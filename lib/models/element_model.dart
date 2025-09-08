class ElementModel {
  final int id;
  final int siteId;
  final String name;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  ElementModel({
    required this.id,
    required this.siteId,
    required this.name,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ElementModel.fromJson(Map<String, dynamic> json) {
    return ElementModel(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      name: json['name'] ?? '',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'name': name,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
