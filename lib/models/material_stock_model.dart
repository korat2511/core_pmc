class MaterialStockModel {
  final int status;
  final String currentStock;
  final MaterialDetailModel material;
  final List<StockHistoryModel> data;
  final int totalIn;
  final int totalOut;

  MaterialStockModel({
    required this.status,
    required this.currentStock,
    required this.material,
    required this.data,
    required this.totalIn,
    required this.totalOut,
  });

  factory MaterialStockModel.fromJson(Map<String, dynamic> json) {
    return MaterialStockModel(
      status: json['status'] ?? 0,
      currentStock: json['current_stock']?.toString() ?? '0',
      material: MaterialDetailModel.fromJson(json['material'] ?? {}),
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => StockHistoryModel.fromJson(item))
          .toList() ?? [],
      totalIn: json['total_in'] ?? 0,
      totalOut: json['total_out'] ?? 0,
    );
  }
}

class MaterialDetailModel {
  final int id;
  final String name;
  final String unitOfMeasurement;
  final String specification;
  final int categoryId;
  final String sku;
  final String unitPrice;
  final String gst;
  final String? description;
  final String? brandName;
  final int minStock;
  final String? length;
  final String? weight;
  final String? height;
  final String? width;
  final String? color;
  final String? hsn;
  final String createdAt;
  final String updatedAt;

  MaterialDetailModel({
    required this.id,
    required this.name,
    required this.unitOfMeasurement,
    required this.specification,
    required this.categoryId,
    required this.sku,
    required this.unitPrice,
    required this.gst,
    this.description,
    this.brandName,
    required this.minStock,
    this.length,
    this.weight,
    this.height,
    this.width,
    this.color,
    this.hsn,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialDetailModel.fromJson(Map<String, dynamic> json) {
    return MaterialDetailModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      unitOfMeasurement: json['unit_of_measurement'] ?? '',
      specification: json['specification'] ?? '',
      categoryId: json['category_id'] ?? 0,
      sku: json['sku'] ?? '',
      unitPrice: json['unit_price']?.toString() ?? '0',
      gst: json['gst'] ?? '',
      description: json['description'],
      brandName: json['brand_name'],
      minStock: json['min_stock'] ?? 0,
      length: json['length']?.toString(),
      weight: json['weight']?.toString(),
      height: json['height']?.toString(),
      width: json['width']?.toString(),
      color: json['color'],
      hsn: json['hsn'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class StockHistoryModel {
  final int id;
  final int materialId;
  final int? siteId;
  final String type;
  final String quantity;
  final String? price;
  final int userId;
  final String description;
  final int? progressId;
  final int? currentStock;
  final int? grnId;
  final String createdAt;
  final String updatedAt;
  final SiteModel? site;
  final dynamic progress;
  final GRNModel? grn;
  final UserModel? user;

  StockHistoryModel({
    required this.id,
    required this.materialId,
    this.siteId,
    required this.type,
    required this.quantity,
    this.price,
    required this.userId,
    required this.description,
    this.progressId,
    this.currentStock,
    this.grnId,
    required this.createdAt,
    required this.updatedAt,
    this.site,
    this.progress,
    this.grn,
    this.user,
  });

  factory StockHistoryModel.fromJson(Map<String, dynamic> json) {
    return StockHistoryModel(
      id: json['id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      siteId: json['site_id'],
      type: json['type'] ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      price: json['price']?.toString(),
      userId: json['user_id'] ?? 0,
      description: json['description'] ?? '',
      progressId: json['progress_id'],
      currentStock: json['current_stock'],
      grnId: json['grn_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      site: json['site'] != null ? SiteModel.fromJson(json['site']) : null,
      progress: json['progress'],
      grn: json['grn'] != null ? GRNModel.fromJson(json['grn']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class SiteModel {
  final int id;
  final String name;
  final String clientName;
  final String architectName;
  final int userId;
  final String company;
  final String startDate;
  final String endDate;
  final String status;
  final String latitude;
  final String longitude;
  final int minRange;
  final int maxRange;
  final String? address;
  final String createdAt;
  final String updatedAt;

  SiteModel({
    required this.id,
    required this.name,
    required this.clientName,
    required this.architectName,
    required this.userId,
    required this.company,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.minRange,
    required this.maxRange,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      clientName: json['client_name'] ?? '',
      architectName: json['architect_name'] ?? '',
      userId: json['user_id'] ?? 0,
      company: json['company'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      minRange: json['min_range'] ?? 0,
      maxRange: json['max_range'] ?? 0,
      address: json['address'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class GRNModel {
  final int id;
  final String grnDate;
  final String grnNumber;
  final String grnIntNumber;
  final String deliveryChallanNumber;
  final int vendorId;
  final int siteId;
  final String remarks;
  final int? poId;
  final int userId;
  final String createdAt;
  final String updatedAt;

  GRNModel({
    required this.id,
    required this.grnDate,
    required this.grnNumber,
    required this.grnIntNumber,
    required this.deliveryChallanNumber,
    required this.vendorId,
    required this.siteId,
    required this.remarks,
    this.poId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GRNModel.fromJson(Map<String, dynamic> json) {
    return GRNModel(
      id: json['id'] ?? 0,
      grnDate: json['grn_date'] ?? '',
      grnNumber: json['grn_number'] ?? '',
      grnIntNumber: json['grn_int_number'] ?? '',
      deliveryChallanNumber: json['delivery_challan_number'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      remarks: json['remarks'] ?? '',
      poId: json['po_id'],
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final int userType;
  final String status;
  final String siteId;
  final String? image;
  final String lastActiveTime;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.userType,
    required this.status,
    required this.siteId,
    this.image,
    required this.lastActiveTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 0,
      status: json['status'] ?? '',
      siteId: json['site_id'] ?? '',
      image: json['image'],
      lastActiveTime: json['last_active_time'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
}
