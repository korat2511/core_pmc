class POModel {
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

  POModel({
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
  });

  factory POModel.fromJson(Map<String, dynamic> json) {
    return POModel(
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
    };
  }

  POModel copyWith({
    int? id,
    int? userId,
    int? siteId,
    String? subtotal,
    String? cgst,
    String? sgst,
    String? igst,
    String? grandTotal,
    String? purchaseOrderId,
    int? orderIdInInt,
    String? vendorName,
    int? vendorId,
    String? expectedDeliveryDate,
    String? deliveryAddress,
    String? deliveryState,
    String? deliveryContactName,
    String? deliveryContactNo,
    String? billingAddress,
    String? billingState,
    String? billingCompanyName,
    String? billingGstin,
    String? vendorPhoneNo,
    String? termsAndConditions,
    String? paymentTerms,
    String? status,
    String? deletedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return POModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      siteId: siteId ?? this.siteId,
      subtotal: subtotal ?? this.subtotal,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      grandTotal: grandTotal ?? this.grandTotal,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      orderIdInInt: orderIdInInt ?? this.orderIdInInt,
      vendorName: vendorName ?? this.vendorName,
      vendorId: vendorId ?? this.vendorId,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryState: deliveryState ?? this.deliveryState,
      deliveryContactName: deliveryContactName ?? this.deliveryContactName,
      deliveryContactNo: deliveryContactNo ?? this.deliveryContactNo,
      billingAddress: billingAddress ?? this.billingAddress,
      billingState: billingState ?? this.billingState,
      billingCompanyName: billingCompanyName ?? this.billingCompanyName,
      billingGstin: billingGstin ?? this.billingGstin,
      vendorPhoneNo: vendorPhoneNo ?? this.vendorPhoneNo,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
