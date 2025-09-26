import 'manpower_model.dart';

class ManpowerResponse {
  final int status;
  final String message;
  final List<ManpowerModel> data;
  final String whatsAppMessage;

  ManpowerResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.whatsAppMessage,
  });

  factory ManpowerResponse.fromJson(Map<String, dynamic> json) {
    List<ManpowerModel> manpowerList = [];
    
    if (json['data'] != null && json['data'] is List) {
      manpowerList = (json['data'] as List<dynamic>)
          .map((manpower) => ManpowerModel.fromJson(manpower))
          .toList();
    }
    
    return ManpowerResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? 'Success', // Default message if not provided
      data: manpowerList,
      whatsAppMessage: json['whats_app_message'] ?? '',
    );
  }

  bool get isSuccess => status == 1;
}
