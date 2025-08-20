import 'qc_point_model.dart';

class QcPointResponse {
  final int status;
  final String message;
  final List<QcPointModel> points;

  QcPointResponse({
    required this.status,
    required this.message,
    required this.points,
  });

  factory QcPointResponse.fromJson(Map<String, dynamic> json) {
    return QcPointResponse(
      status: json['status'] is int ? json['status'] : int.tryParse(json['status'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      points: json['points'] != null
          ? (json['points'] as List<dynamic>)
              .map((point) => QcPointModel.fromJson(point))
              .toList()
          : [],
    );
  }

  bool get isSuccess => status == 1;
}
