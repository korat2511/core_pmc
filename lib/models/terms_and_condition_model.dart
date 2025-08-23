class TermsAndConditionModel {
  final int id;
  final int userId;
  final String termAndCondition;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  TermsAndConditionModel({
    required this.id,
    required this.userId,
    required this.termAndCondition,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TermsAndConditionModel.fromJson(Map<String, dynamic> json) {
    return TermsAndConditionModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      termAndCondition: json['term_and_condition'] ?? '',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'term_and_condition': termAndCondition,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class TermsAndConditionResponse {
  final int status;
  final List<TermsAndConditionModel> data;

  TermsAndConditionResponse({
    required this.status,
    required this.data,
  });

  factory TermsAndConditionResponse.fromJson(Map<String, dynamic> json) {
    return TermsAndConditionResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => TermsAndConditionModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
