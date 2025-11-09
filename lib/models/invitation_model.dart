class InvitationModel {
  final int id;
  final int inviterId;
  final int companyId;
  final int designationId;
  final String inviteCode;
  final String status;
  final String? fullName;
  final String? email;
  final String? mobile;
  final String? channel;
  final String? notes;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? designation;
  final Map<String, dynamic>? company;

  InvitationModel({
    required this.id,
    required this.inviterId,
    required this.companyId,
    required this.designationId,
    required this.inviteCode,
    required this.status,
    required this.createdAt,
    this.fullName,
    this.email,
    this.mobile,
    this.channel,
    this.notes,
    this.expiresAt,
    this.acceptedAt,
    this.revokedAt,
    this.meta,
    this.designation,
    this.company,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return InvitationModel(
      id: json['id'] ?? 0,
      inviterId: json['inviter_id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      designationId: json['designation_id'] ?? 0,
      inviteCode: json['invite_code'] ?? '',
      status: json['status'] ?? 'pending',
      fullName: json['full_name'],
      email: json['email'],
      mobile: json['mobile'],
      channel: json['channel'],
      notes: json['notes'],
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      expiresAt: parseDate(json['expires_at']),
      acceptedAt: parseDate(json['accepted_at']),
      revokedAt: parseDate(json['revoked_at']),
      meta: json['meta'] is Map<String, dynamic> ? json['meta'] as Map<String, dynamic> : null,
      designation: json['designation'] is Map<String, dynamic> ? json['designation'] as Map<String, dynamic> : null,
      company: json['company'] is Map<String, dynamic> ? json['company'] as Map<String, dynamic> : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRevoked => status == 'revoked';
  bool get isExpired => status == 'expired';

  String get statusDisplay {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'revoked':
        return 'Revoked';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
    }
  }
}


