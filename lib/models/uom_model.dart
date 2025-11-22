class UOMModel {
  final String id;
  final String abbreviation;
  final String fullName;
  final String category;
  final String? userId; // null for default units, userId for custom units
  final DateTime createdAt;
  final DateTime updatedAt;

  UOMModel({
    required this.id,
    required this.abbreviation,
    required this.fullName,
    required this.category,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UOMModel.fromJson(Map<String, dynamic> json) {
    return UOMModel(
      id: json['id']?.toString() ?? '',
      abbreviation: json['abbreviation'] ?? '',
      fullName: json['fullName'] ?? '',
      category: json['category'] ?? '',
      userId: json['userId']?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'abbreviation': abbreviation,
      'fullName': fullName,
      'category': category,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UOMModel copyWith({
    String? id,
    String? abbreviation,
    String? fullName,
    String? category,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UOMModel(
      id: id ?? this.id,
      abbreviation: abbreviation ?? this.abbreviation,
      fullName: fullName ?? this.fullName,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
