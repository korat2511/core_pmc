class BillingAddressModel {
  final int id;
  final int userId;
  final String companyName;
  final String address;
  final String state;
  final String gstin;
  final String createdAt;
  final String updatedAt;

  BillingAddressModel({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.address,
    required this.state,
    required this.gstin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillingAddressModel.fromJson(Map<String, dynamic> json) {
    return BillingAddressModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      companyName: json['company_name'] ?? '',
      address: json['address'] ?? '',
      state: json['state'] ?? '',
      gstin: json['gstin'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_name': companyName,
      'address': address,
      'state': state,
      'gstin': gstin,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class BillingAddressResponse {
  final int status;
  final List<BillingAddressModel> data;

  BillingAddressResponse({
    required this.status,
    required this.data,
  });

  factory BillingAddressResponse.fromJson(Map<String, dynamic> json) {
    return BillingAddressResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => BillingAddressModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class BillingAddressCreateResponse {
  final int status;
  final String message;
  final BillingAddressModel data;

  BillingAddressCreateResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BillingAddressCreateResponse.fromJson(Map<String, dynamic> json) {
    return BillingAddressCreateResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: BillingAddressModel.fromJson(json['data'] ?? {}),
    );
  }
}
