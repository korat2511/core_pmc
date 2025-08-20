import 'tag_model.dart';

class TagResponse {
  final int status;
  final String message;
  final List<TagModel> data;

  TagResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TagResponse.fromJson(Map<String, dynamic> json) {
    return TagResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => TagModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  bool get isSuccess => status == 1;
}
