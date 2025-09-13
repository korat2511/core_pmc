class GrnDetailModel {
  final int id;
  final String grnDate;
  final String grnNumber;
  final String grnIntNumber;
  final String deliveryChallanNumber;
  final int vendorId;
  final int siteId;
  final String remarks;
  final int poId;
  final int userId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final List<GrnLinkedItem> grnsLinkedToSamePo;
  final List<GrnDetailItem> grnDetail;
  final GrnVendor? vendor;
  final List<GrnDocument> grnDocument;
  final List<dynamic> payments;
  final String? siteName;

  GrnDetailModel({
    required this.id,
    required this.grnDate,
    required this.grnNumber,
    required this.grnIntNumber,
    required this.deliveryChallanNumber,
    required this.vendorId,
    required this.siteId,
    required this.remarks,
    required this.poId,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.grnsLinkedToSamePo,
    required this.grnDetail,
    this.vendor,
    required this.grnDocument,
    required this.payments,
    this.siteName,
  });

  factory GrnDetailModel.fromJson(Map<String, dynamic> json) {
    return GrnDetailModel(
      id: json['id'] ?? 0,
      grnDate: json['grn_date'] ?? '',
      grnNumber: json['grn_number'] ?? '',
      grnIntNumber: json['grn_int_number'] ?? '',
      deliveryChallanNumber: json['delivery_challan_number'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      remarks: json['remarks'] ?? '',
      poId: json['po_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      grnsLinkedToSamePo: (json['grns_linked_to_same_po'] as List<dynamic>?)
          ?.map((item) => GrnLinkedItem.fromJson(item))
          .toList() ?? [],
      grnDetail: (json['grn_detail'] as List<dynamic>?)
          ?.map((item) => GrnDetailItem.fromJson(item))
          .toList() ?? [],
      vendor: json['vendor'] != null ? GrnVendor.fromJson(json['vendor']) : null,
      grnDocument: (json['grn_document'] as List<dynamic>?)
          ?.map((item) => GrnDocument.fromJson(item))
          .toList() ?? [],
      payments: json['payments'] ?? [],
      siteName: json['site_name'],
    );
  }
}

class GrnLinkedItem {
  final int id;
  final String grnDate;
  final String grnNumber;
  final String grnIntNumber;
  final String deliveryChallanNumber;
  final int vendorId;
  final int siteId;
  final String remarks;
  final int poId;
  final int userId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  GrnLinkedItem({
    required this.id,
    required this.grnDate,
    required this.grnNumber,
    required this.grnIntNumber,
    required this.deliveryChallanNumber,
    required this.vendorId,
    required this.siteId,
    required this.remarks,
    required this.poId,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory GrnLinkedItem.fromJson(Map<String, dynamic> json) {
    return GrnLinkedItem(
      id: json['id'] ?? 0,
      grnDate: json['grn_date'] ?? '',
      grnNumber: json['grn_number'] ?? '',
      grnIntNumber: json['grn_int_number'] ?? '',
      deliveryChallanNumber: json['delivery_challan_number'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      remarks: json['remarks'] ?? '',
      poId: json['po_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }
}

class GrnDetailItem {
  final int id;
  final int grnId;
  final int materialId;
  final int quantity;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final GrnMaterial? material;

  GrnDetailItem({
    required this.id,
    required this.grnId,
    required this.materialId,
    required this.quantity,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.material,
  });

  factory GrnDetailItem.fromJson(Map<String, dynamic> json) {
    return GrnDetailItem(
      id: json['id'] ?? 0,
      grnId: json['grn_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      material: json['material'] != null ? GrnMaterial.fromJson(json['material']) : null,
    );
  }
}

class GrnMaterial {
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
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  GrnMaterial({
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
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory GrnMaterial.fromJson(Map<String, dynamic> json) {
    return GrnMaterial(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      unitOfMeasurement: json['unit_of_measurement'] ?? '',
      specification: json['specification'] ?? '',
      categoryId: json['category_id'] ?? 0,
      sku: json['sku'] ?? '',
      unitPrice: json['unit_price'] ?? '0',
      gst: json['gst'] ?? '',
      description: json['description'],
      brandName: json['brand_name'],
      minStock: json['min_stock'] ?? 0,
      length: json['length'],
      weight: json['weight'],
      height: json['height'],
      width: json['width'],
      color: json['color'],
      hsn: json['hsn'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }
}

class GrnVendor {
  final int id;
  final int siteId;
  final String? gstNo;
  final String name;
  final String mobile;
  final String email;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  GrnVendor({
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

  factory GrnVendor.fromJson(Map<String, dynamic> json) {
    return GrnVendor(
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
}

class GrnDocument {
  final int id;
  final int grnId;
  final String description;
  final String document;
  final String? createdAt;
  final String? updatedAt;
  final String documentUrl;

  GrnDocument({
    required this.id,
    required this.grnId,
    required this.description,
    required this.document,
    this.createdAt,
    this.updatedAt,
    required this.documentUrl,
  });

  factory GrnDocument.fromJson(Map<String, dynamic> json) {
    return GrnDocument(
      id: json['id'] ?? 0,
      grnId: json['grn_id'] ?? 0,
      description: json['description'] ?? '',
      document: json['document'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      documentUrl: json['document_url'] ?? '',
    );
  }
}
