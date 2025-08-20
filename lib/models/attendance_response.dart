import 'attendance_model.dart';

class AttendanceResponse {
  final int status;
  final List<AttendanceModel> data;
  final int total;

  AttendanceResponse({
    required this.status,
    required this.data,
    required this.total,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => AttendanceModel.fromJson(item))
          .toList() ?? [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }

  bool get isSuccess => status == 1;
}
