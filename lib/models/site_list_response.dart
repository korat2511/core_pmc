import 'site_model.dart';

class SiteListResponse {
  final int status;
  final String message;
  final List<SiteModel> data;

  SiteListResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SiteListResponse.fromJson(Map<String, dynamic> json) {
    return SiteListResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((site) => SiteModel.fromJson(site))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((site) => site.toJson()).toList(),
    };
  }

  bool get isSuccess => status == 1;
  bool get isError => status != 1;
} 