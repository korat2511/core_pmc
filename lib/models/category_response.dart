import 'category_model.dart';

class CategoryResponse {
  final int status;
  final String message;
  final List<CategoryModel> categories;

  CategoryResponse({
    required this.status,
    required this.message,
    required this.categories,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    List<CategoryModel> categories = [];
    
    if (json['data'] != null && json['data'] is List) {
      categories = (json['data'] as List<dynamic>)
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    }
    
    return CategoryResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      categories: categories,
    );
  }

  bool get isSuccess => status == 1;
}
