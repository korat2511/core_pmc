import 'material_model.dart';
import 'site_model.dart';

class PODetailModel {
  final int id;
  final int userId;
  final int siteId;
  final String subtotal;
  final String cgst;
  final String sgst;
  final String igst;
  final String grandTotal;
  final String purchaseOrderId;
  final int orderIdInInt;
  final String vendorName;
  final int vendorId;
  final String expectedDeliveryDate;
  final String deliveryAddress;
  final String deliveryState;
  final String deliveryContactName;
  final String deliveryContactNo;
  final String billingAddress;
  final String billingState;
  final String billingCompanyName;
  final String billingGstin;
  final String vendorPhoneNo;
  final String? termsAndConditions;
  final String? paymentTerms;
  final String status;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final List<PendingItem> pendingItems;
  final List<DeliveredItem> deliveredItems;
  final SiteModel site;
  final List<POPayment> poPayment;
  final Vendor vendor;
  final List<GRN> grn;

  PODetailModel({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.grandTotal,
    required this.purchaseOrderId,
    required this.orderIdInInt,
    required this.vendorName,
    required this.vendorId,
    required this.expectedDeliveryDate,
    required this.deliveryAddress,
    required this.deliveryState,
    required this.deliveryContactName,
    required this.deliveryContactNo,
    required this.billingAddress,
    required this.billingState,
    required this.billingCompanyName,
    required this.billingGstin,
    required this.vendorPhoneNo,
    this.termsAndConditions,
    this.paymentTerms,
    required this.status,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.pendingItems,
    required this.deliveredItems,
    required this.site,
    required this.poPayment,
    required this.vendor,
    required this.grn,
  });

  factory PODetailModel.fromJson(Map<String, dynamic> json) {
    return PODetailModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      subtotal: json['subtotal'] ?? '0.00',
      cgst: json['cgst'] ?? '0.00',
      sgst: json['sgst'] ?? '0.00',
      igst: json['igst'] ?? '0.00',
      grandTotal: json['grand_total'] ?? '0.00',
      purchaseOrderId: json['purchase_order_id'] ?? '',
      orderIdInInt: json['order_id_in_int'] ?? 0,
      vendorName: json['vendor_name'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      expectedDeliveryDate: json['expected_delivery_date'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryState: json['delivery_state'] ?? '',
      deliveryContactName: json['delivery_contact_name'] ?? '',
      deliveryContactNo: json['delivery_contact_no'] ?? '',
      billingAddress: json['billing_address'] ?? '',
      billingState: json['billing_state'] ?? '',
      billingCompanyName: json['billing_company_name'] ?? '',
      billingGstin: json['billing_gstin'] ?? '',
      vendorPhoneNo: json['vendor_phone_no'] ?? '',
      termsAndConditions: json['terms_and_conditions'],
      paymentTerms: json['payment_terms'],
      status: json['status'] ?? 'pending',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      pendingItems: (json['pending_iteam'] as List<dynamic>?)
          ?.map((item) => PendingItem.fromJson(item))
          .toList() ?? [],
      deliveredItems: (json['delivered_iteam'] as List<dynamic>?)
          ?.map((item) => DeliveredItem.fromJson(item))
          .toList() ?? [],
      site: SiteModel.fromJson(json['site'] ?? {}),
      poPayment: (json['po_payment'] as List<dynamic>?)
          ?.map((item) => POPayment.fromJson(item))
          .toList() ?? [],
      vendor: Vendor.fromJson(json['vendor'] ?? {}),
      grn: (json['grn'] as List<dynamic>?)
          ?.map((item) => GRN.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'site_id': siteId,
      'subtotal': subtotal,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'grand_total': grandTotal,
      'purchase_order_id': purchaseOrderId,
      'order_id_in_int': orderIdInInt,
      'vendor_name': vendorName,
      'vendor_id': vendorId,
      'expected_delivery_date': expectedDeliveryDate,
      'delivery_address': deliveryAddress,
      'delivery_state': deliveryState,
      'delivery_contact_name': deliveryContactName,
      'delivery_contact_no': deliveryContactNo,
      'billing_address': billingAddress,
      'billing_state': billingState,
      'billing_company_name': billingCompanyName,
      'billing_gstin': billingGstin,
      'vendor_phone_no': vendorPhoneNo,
      'terms_and_conditions': termsAndConditions,
      'payment_terms': paymentTerms,
      'status': status,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pending_iteam': pendingItems.map((item) => item.toJson()).toList(),
      'delivered_iteam': deliveredItems.map((item) => item.toJson()).toList(),
      'site': site.toJson(),
      'po_payment': poPayment,
      'vendor': vendor.toJson(),
      'grn': grn,
    };
  }
}

class PendingItem {
  final int id;
  final int materialId;
  final int materialPoId;
  final String unitPrice;
  final String discountValue;
  final String discountType;
  final String quantityForDelivery;
  final String sgst;
  final String cgst;
  final String igst;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final int pendingQuantity;
  final MaterialModel material;

  PendingItem({
    required this.id,
    required this.materialId,
    required this.materialPoId,
    required this.unitPrice,
    required this.discountValue,
    required this.discountType,
    required this.quantityForDelivery,
    required this.sgst,
    required this.cgst,
    required this.igst,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.pendingQuantity,
    required this.material,
  });

  factory PendingItem.fromJson(Map<String, dynamic> json) {
    return PendingItem(
      id: json['id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      materialPoId: json['material_po_id'] ?? 0,
      unitPrice: json['unit_price'] ?? '0.00',
      discountValue: json['discount_value'] ?? '0.00',
      discountType: json['discount_type'] ?? 'percentage',
      quantityForDelivery: json['quantity_for_delivery'] ?? '0.00',
      sgst: json['sgst'] ?? '0.00',
      cgst: json['cgst'] ?? '0.00',
      igst: json['igst'] ?? '0.00',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      pendingQuantity: json['pending_quantity'] ?? 0,
      material: MaterialModel.fromJson(json['material'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material_id': materialId,
      'material_po_id': materialPoId,
      'unit_price': unitPrice,
      'discount_value': discountValue,
      'discount_type': discountType,
      'quantity_for_delivery': quantityForDelivery,
      'sgst': sgst,
      'cgst': cgst,
      'igst': igst,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pending_quantity': pendingQuantity,
      'material': material.toJson(),
    };
  }
}

class DeliveredItem {
  final int id;
  final int? grnId;
  final int materialId;
  final int quantity;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final User? user;
  final MaterialModel material;
  final String? orderedQuantity; // Original ordered quantity from PO

  DeliveredItem({
    required this.id,
    this.grnId,
    required this.materialId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.user,
    required this.material,
    this.orderedQuantity,
  });

  factory DeliveredItem.fromJson(Map<String, dynamic> json) {
    return DeliveredItem(
      id: json['id'] ?? 0,
      grnId: json['grn_id'],
      materialId: json['material_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      material: MaterialModel.fromJson(json['material'] ?? {}),
      orderedQuantity: json['ordered_quantity']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grn_id': grnId,
      'material_id': materialId,
      'quantity': quantity,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'user': user?.toJson(),
      'material': material.toJson(),
    };
  }
}

class User {
  final int id;
  final String firstName;
  final String? apiToken;
  final String lastName;
  final String? deviceId;
  final String mobile;
  final String email;
  final String? designation;
  final String status;
  final String siteId;
  final String? image;
  final String? lastActiveTime;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? imageUrl;

  User({
    required this.id,
    required this.firstName,
    this.apiToken,
    required this.lastName,
    this.deviceId,
    required this.mobile,
    required this.email,
    this.designation,
    required this.status,
    required this.siteId,
    this.image,
    this.lastActiveTime,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.imageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      apiToken: json['api_token'],
      lastName: json['last_name'] ?? '',
      deviceId: json['device_id'],
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      designation: json['designation'],
      status: json['status'] ?? '',
      siteId: json['site_id'] ?? '',
      image: json['image'],
      lastActiveTime: json['last_active_time'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'api_token': apiToken,
      'last_name': lastName,
      'device_id': deviceId,
      'mobile': mobile,
      'email': email,
      'designation': designation,
      'status': status,
      'site_id': siteId,
      'image': image,
      'last_active_time': lastActiveTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image_url': imageUrl,
    };
  }
  
  String get designationDisplay => designation ?? 'Employee';
}

class POPayment {
  final int id;
  final int poId;
  final int? grnId;
  final String paymentDate;
  final String paymentAmount;
  final String paymentMode;
  final String advanceId;
  final int advanceIdInt;
  final String? transactionId;
  final int userId;
  final String? remark;
  final String createdAt;
  final String updatedAt;
  final List<dynamic> poPaymentDocument;
  final User user;

  POPayment({
    required this.id,
    required this.poId,
    this.grnId,
    required this.paymentDate,
    required this.paymentAmount,
    required this.paymentMode,
    required this.advanceId,
    required this.advanceIdInt,
    this.transactionId,
    required this.userId,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
    required this.poPaymentDocument,
    required this.user,
  });

  factory POPayment.fromJson(Map<String, dynamic> json) {
    return POPayment(
      id: json['id'] ?? 0,
      poId: json['po_id'] ?? 0,
      grnId: json['grn_id'],
      paymentDate: json['payment_date'] ?? '',
      paymentAmount: json['payment_amount'] ?? '0.00',
      paymentMode: json['payment_mode'] ?? '',
      advanceId: json['advance_id'] ?? '',
      advanceIdInt: json['advance_id_int'] ?? 0,
      transactionId: json['transaction_id'],
      userId: json['user_id'] ?? 0,
      remark: json['remark'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      poPaymentDocument: json['po_payment_document'] ?? [],
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_id': poId,
      'grn_id': grnId,
      'payment_date': paymentDate,
      'payment_amount': paymentAmount,
      'payment_mode': paymentMode,
      'advance_id': advanceId,
      'advance_id_int': advanceIdInt,
      'transaction_id': transactionId,
      'user_id': userId,
      'remark': remark,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'po_payment_document': poPaymentDocument,
      'user': user.toJson(),
    };
  }
}

class GRN {
  final int id;
  final String grnDate;
  final String grnNumber;
  final String grnIntNumber;
  final String deliveryChallanNumber;
  final int vendorId;
  final int siteId;
  final String? remarks;
  final int poId;
  final int? userId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  GRN({
    required this.id,
    required this.grnDate,
    required this.grnNumber,
    required this.grnIntNumber,
    required this.deliveryChallanNumber,
    required this.vendorId,
    required this.siteId,
    this.remarks,
    required this.poId,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory GRN.fromJson(Map<String, dynamic> json) {
    return GRN(
      id: json['id'] ?? 0,
      grnDate: json['grn_date'] ?? '',
      grnNumber: json['grn_number'] ?? '',
      grnIntNumber: json['grn_int_number'] ?? '',
      deliveryChallanNumber: json['delivery_challan_number'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      remarks: json['remarks'],
      poId: json['po_id'] ?? 0,
      userId: json['user_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grn_date': grnDate,
      'grn_number': grnNumber,
      'grn_int_number': grnIntNumber,
      'delivery_challan_number': deliveryChallanNumber,
      'vendor_id': vendorId,
      'site_id': siteId,
      'remarks': remarks,
      'po_id': poId,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}

class Vendor {
  final int id;
  final int siteId;
  final String? gstNo;
  final String name;
  final String mobile;
  final String email;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  Vendor({
    required this.id,
    required this.siteId,
    this.gstNo,
    required this.name,
    required this.mobile,
    required this.email,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      gstNo: json['gst_no'],
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'gst_no': gstNo,
      'name': name,
      'mobile': mobile,
      'email': email,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
