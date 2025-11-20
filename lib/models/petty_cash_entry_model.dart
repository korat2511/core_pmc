class PettyCashEntryModel {
  final int id;
  final int siteId;
  final int? companyId;
  final String ledgerType; // 'spent' or 'received'
  final double amount;
  final String paymentMode; // 'cash', 'bank', 'upi', 'other'
  
  // For received entries
  final String? receivedBy;
  final String? receivedVia;
  final String? receivedFrom;
  final String? receivedFromType;
  final int? receivedFromId;
  final String? receivedFromName;
  
  // For spent entries
  final String? paidBy;
  final String? paidVia;
  final String? paidTo;
  final String? paidToType;
  final int? paidToId;
  final String? paidToName;
  
  final String? transactionId;
  final String? remark;
  final String entryDate;
  final int userId;
  final String? createdAt;
  final String? updatedAt;
  
  // Relationships
  final Map<String, dynamic>? site;
  final Map<String, dynamic>? company;
  final Map<String, dynamic>? user;
  final List<PettyCashImageModel> images;

  PettyCashEntryModel({
    required this.id,
    required this.siteId,
    this.companyId,
    required this.ledgerType,
    required this.amount,
    required this.paymentMode,
    this.receivedBy,
    this.receivedVia,
    this.receivedFrom,
    this.receivedFromType,
    this.receivedFromId,
    this.receivedFromName,
    this.paidBy,
    this.paidVia,
    this.paidTo,
    this.paidToType,
    this.paidToId,
    this.paidToName,
    this.transactionId,
    this.remark,
    required this.entryDate,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    this.site,
    this.company,
    this.user,
    required this.images,
  });

  factory PettyCashEntryModel.fromJson(Map<String, dynamic> json) {
    return PettyCashEntryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      siteId: json['site_id'] is int ? json['site_id'] : int.tryParse(json['site_id']?.toString() ?? '0') ?? 0,
      companyId: json['company_id'] == null 
          ? null 
          : json['company_id'] is int 
              ? json['company_id'] 
              : int.tryParse(json['company_id']?.toString() ?? ''),
      ledgerType: json['ledger_type'] ?? '',
      amount: json['amount'] is double 
          ? json['amount'] 
          : json['amount'] is int 
              ? json['amount'].toDouble() 
              : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMode: json['payment_mode'] ?? 'cash',
      receivedBy: json['received_by'],
      receivedVia: json['received_via'],
      receivedFrom: json['received_from'],
      receivedFromType: json['received_from_type'],
      receivedFromId: json['received_from_id'] == null 
          ? null 
          : json['received_from_id'] is int 
              ? json['received_from_id'] 
              : int.tryParse(json['received_from_id']?.toString() ?? ''),
      receivedFromName: json['received_from_name'],
      paidBy: json['paid_by'],
      paidVia: json['paid_via'],
      paidTo: json['paid_to'],
      paidToType: json['paid_to_type'],
      paidToId: json['paid_to_id'] == null 
          ? null 
          : json['paid_to_id'] is int 
              ? json['paid_to_id'] 
              : int.tryParse(json['paid_to_id']?.toString() ?? ''),
      paidToName: json['paid_to_name'],
      transactionId: json['transaction_id'],
      remark: json['remark'],
      entryDate: json['entry_date'] ?? '',
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      site: json['site'],
      company: json['company'],
      user: json['user'],
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => PettyCashImageModel.fromJson(img))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'company_id': companyId,
      'ledger_type': ledgerType,
      'amount': amount,
      'payment_mode': paymentMode,
      'received_by': receivedBy,
      'received_via': receivedVia,
      'received_from': receivedFrom,
      'received_from_type': receivedFromType,
      'received_from_id': receivedFromId,
      'received_from_name': receivedFromName,
      'paid_by': paidBy,
      'paid_via': paidVia,
      'paid_to': paidTo,
      'paid_to_type': paidToType,
      'paid_to_id': paidToId,
      'paid_to_name': paidToName,
      'transaction_id': transactionId,
      'remark': remark,
      'entry_date': entryDate,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class PettyCashImageModel {
  final int id;
  final int pettyCashEntryId;
  final String image;
  final String? imagePath;

  PettyCashImageModel({
    required this.id,
    required this.pettyCashEntryId,
    required this.image,
    this.imagePath,
  });

  factory PettyCashImageModel.fromJson(Map<String, dynamic> json) {
    return PettyCashImageModel(
      id: json['id'] ?? 0,
      pettyCashEntryId: json['petty_cash_entry_id'] ?? 0,
      image: json['image'] ?? '',
      imagePath: json['image_path'],
    );
  }
}

class PettyCashOptionModel {
  final int? id;
  final String name;
  final String? email;
  final String? mobile;

  PettyCashOptionModel({
    this.id,
    required this.name,
    this.email,
    this.mobile,
  });

  factory PettyCashOptionModel.fromJson(Map<String, dynamic> json) {
    return PettyCashOptionModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      mobile: json['mobile'],
    );
  }
}
