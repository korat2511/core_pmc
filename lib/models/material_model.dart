class MaterialModel {
  final int id;
  final String name;
  final String unitOfMeasurement;
  final String? specification;
  final int categoryId;
  final String sku;
  final String unitPrice;
  final String gst;
  final String? description;
  final String? brandName;
  final int minStock;
  final String? length;
  final String? width;
  final String? height;
  final String? weight;
  final String? color;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? currentStock;

  MaterialModel({
    required this.id,
    required this.name,
    required this.unitOfMeasurement,
    this.specification,
    required this.categoryId,
    required this.sku,
    required this.unitPrice,
    required this.gst,
    this.description,
    this.brandName,
    required this.minStock,
    this.length,
    this.width,
    this.height,
    this.weight,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.currentStock,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      unitOfMeasurement: json['unit_of_measurement'] ?? '',
      specification: json['specification'],
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      sku: json['sku'] ?? '',
      unitPrice: json['unit_price']?.toString() ?? '0',
      gst: json['gst'] ?? '',
      description: json['description'],
      brandName: json['brand_name'],
      minStock: int.tryParse(json['min_stock'].toString()) ?? 0,
      length: json['length']?.toString(),
      width: json['width']?.toString(),
      height: json['height']?.toString(),
      weight: json['weight']?.toString(),
      color: json['color'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      currentStock: json['current_stock']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit_of_measurement': unitOfMeasurement,
      'specification': specification,
      'category_id': categoryId,
      'sku': sku,
      'unit_price': unitPrice,
      'gst': gst,
      'description': description,
      'brand_name': brandName,
      'min_stock': minStock,
      'length': length,
      'width': width,
      'height': height,
      'weight': weight,
      'color': color,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'current_stock': currentStock,
    };
  }
}

class MaterialResponse {
  final int status;
  final List<MaterialModel> data;

  MaterialResponse({
    required this.status,
    required this.data,
  });

  factory MaterialResponse.fromJson(Map<String, dynamic> json) {
    return MaterialResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => MaterialModel.fromJson(item))
          .toList() ?? [],
    );
  }
}

class MaterialCreateResponse {
  final int status;
  final String message;
  final MaterialModel data;

  MaterialCreateResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MaterialCreateResponse.fromJson(Map<String, dynamic> json) {
    return MaterialCreateResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: MaterialModel.fromJson(json['data'] ?? {}),
    );
  }
}
