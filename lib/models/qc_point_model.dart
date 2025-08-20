class QcPointModel {
  final int id;
  final String type;
  final int categoryId;
  final String point;
  final String createdAt;
  final String updatedAt;

  QcPointModel({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.point,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QcPointModel.fromJson(Map<String, dynamic> json) {
    return QcPointModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type']?.toString() ?? '',
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 0,
      point: json['point']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category_id': categoryId,
      'point': point,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isPre => type == 'pre';
  bool get isDuring => type == 'during';
  bool get isAfter => type == 'after';
}
