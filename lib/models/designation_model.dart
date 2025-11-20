class DesignationModel {
  final int id;
  final int companyId;
  final String name;
  final int order;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  DesignationModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.order,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory DesignationModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int _toInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    return DesignationModel(
      id: _toInt(json['id'], 0),
      companyId: _toInt(json['company_id'], 0),
      name: json['name']?.toString() ?? '',
      order: _toInt(json['order'], 0),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'order': order,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isInactive => status.toLowerCase() == 'inactive';

  DesignationModel copyWith({
    int? id,
    int? companyId,
    String? name,
    int? order,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return DesignationModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      order: order ?? this.order,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class DesignationResponse {
  final int status;
  final String message;
  final List<DesignationModel>? data;

  DesignationResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory DesignationResponse.fromJson(Map<String, dynamic> json) {
    return DesignationResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List<dynamic>)
              .map((d) => DesignationModel.fromJson(d))
              .toList()
          : null,
    );
  }

  bool get isSuccess => status == 1;
}

