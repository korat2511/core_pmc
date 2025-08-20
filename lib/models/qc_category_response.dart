import 'qc_category_model.dart';

class QcCategoryResponse {
  final int status;
  final String message;
  final List<QcCategoryModel> points;

  QcCategoryResponse({
    required this.status,
    required this.message,
    required this.points,
  });

  factory QcCategoryResponse.fromJson(Map<String, dynamic> json) {
    return QcCategoryResponse(
      status: json['status'] is int ? json['status'] : int.tryParse(json['status'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      points: json['points'] != null
          ? (json['points'] as List<dynamic>)
              .map((point) => QcCategoryModel.fromJson(point))
              .toList()
          : [],
    );
  }

  bool get isSuccess => status == 1;
}
