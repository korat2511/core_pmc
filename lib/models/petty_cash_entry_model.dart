
class PettyCashEntry {
  final String id;
  final String siteId;
  final String siteName;
  final String ledgerType; // 'received' or 'spent'
  final double amount;
  final String receivedBy; // For received entries
  final String paidBy; // For spent entries
  final String receivedVia; // For received entries (cash, bank, etc.)
  final String paidVia; // For spent entries (cash, bank, etc.)
  final String receivedFrom; // For received entries
  final String paidTo; // For spent entries
  final String? transactionId; // For non-cash payments
  final String? paidToType; // 'site_engineer', 'project_co_ordinator', 'agency', 'vendor', 'other'
  final int? paidToId; // ID of selected user/agency/vendor
  final String? paidToName; // Name of selected user/agency/vendor
  final String? otherRecipient; // For 'other' type
  final List<String> imageUrls; // Firebase storage URLs
  final String remark;
  final DateTime entryDate;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;

  PettyCashEntry({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.ledgerType,
    required this.amount,
    required this.receivedBy,
    required this.paidBy,
    required this.receivedVia,
    required this.paidVia,
    required this.receivedFrom,
    required this.paidTo,
    this.transactionId,
    this.paidToType,
    this.paidToId,
    this.paidToName,
    this.otherRecipient,
    required this.imageUrls,
    required this.remark,
    required this.entryDate,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
  });

  factory PettyCashEntry.fromMap(Map<String, dynamic> map) {
    return PettyCashEntry(
      id: map['id'] ?? '',
      siteId: map['site_id'] ?? '',
      siteName: map['site_name'] ?? '',
      ledgerType: map['ledger_type'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      receivedBy: map['received_by'] ?? '',
      paidBy: map['paid_by'] ?? '',
      receivedVia: map['received_via'] ?? '',
      paidVia: map['paid_via'] ?? '',
      receivedFrom: map['received_from'] ?? '',
      paidTo: map['paid_to'] ?? '',
      transactionId: map['transaction_id'],
      paidToType: map['paid_to_type'],
      paidToId: map['paid_to_id'],
      paidToName: map['paid_to_name'],
      otherRecipient: map['other_recipient'],
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      remark: map['remark'] ?? '',
      entryDate: DateTime.parse(map['entry_date']),
      createdAt: DateTime.parse(map['created_at']),
      createdBy: map['created_by'] ?? '',
      createdByName: map['created_by_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      'site_name': siteName,
      'ledger_type': ledgerType,
      'amount': amount,
      'received_by': receivedBy,
      'paid_by': paidBy,
      'received_via': receivedVia,
      'paid_via': paidVia,
      'received_from': receivedFrom,
      'paid_to': paidTo,
      'transaction_id': transactionId,
      'paid_to_type': paidToType,
      'paid_to_id': paidToId,
      'paid_to_name': paidToName,
      'other_recipient': otherRecipient,
      'image_urls': imageUrls,
      'remark': remark,
      'entry_date': entryDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'created_by_name': createdByName,
    };
  }

  PettyCashEntry copyWith({
    String? id,
    String? siteId,
    String? siteName,
    String? ledgerType,
    double? amount,
    String? receivedBy,
    String? paidBy,
    String? receivedVia,
    String? paidVia,
    String? receivedFrom,
    String? paidTo,
    String? transactionId,
    String? paidToType,
    int? paidToId,
    String? paidToName,
    String? otherRecipient,
    List<String>? imageUrls,
    String? remark,
    DateTime? entryDate,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
  }) {
    return PettyCashEntry(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      ledgerType: ledgerType ?? this.ledgerType,
      amount: amount ?? this.amount,
      receivedBy: receivedBy ?? this.receivedBy,
      paidBy: paidBy ?? this.paidBy,
      receivedVia: receivedVia ?? this.receivedVia,
      paidVia: paidVia ?? this.paidVia,
      receivedFrom: receivedFrom ?? this.receivedFrom,
      paidTo: paidTo ?? this.paidTo,
      transactionId: transactionId ?? this.transactionId,
      paidToType: paidToType ?? this.paidToType,
      paidToId: paidToId ?? this.paidToId,
      paidToName: paidToName ?? this.paidToName,
      otherRecipient: otherRecipient ?? this.otherRecipient,
      imageUrls: imageUrls ?? this.imageUrls,
      remark: remark ?? this.remark,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}

class PettyCashBalance {
  final String siteId;
  final String siteName;
  final double totalReceived;
  final double totalSpent;
  final double currentBalance;
  final DateTime lastUpdated;

  PettyCashBalance({
    required this.siteId,
    required this.siteName,
    required this.totalReceived,
    required this.totalSpent,
    required this.currentBalance,
    required this.lastUpdated,
  });

  factory PettyCashBalance.fromMap(Map<String, dynamic> map) {
    return PettyCashBalance(
      siteId: map['site_id'] ?? '',
      siteName: map['site_name'] ?? '',
      totalReceived: (map['total_received'] ?? 0.0).toDouble(),
      totalSpent: (map['total_spent'] ?? 0.0).toDouble(),
      currentBalance: (map['current_balance'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'site_id': siteId,
      'site_name': siteName,
      'total_received': totalReceived,
      'total_spent': totalSpent,
      'current_balance': currentBalance,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
