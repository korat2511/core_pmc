import 'category_model.dart';

class ManpowerModel {
  final int id;
  final int siteId;
  final int userId;
  final int categoryId;
  final int skilledWorker;
  final int unskilledWorker;
  final String date;
  final int shift;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final CategoryModel category;

  ManpowerModel({
    required this.id,
    required this.siteId,
    required this.userId,
    required this.categoryId,
    required this.skilledWorker,
    required this.unskilledWorker,
    required this.date,
    required this.shift,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.category,
  });

  factory ManpowerModel.fromJson(Map<String, dynamic> json) {
    return ManpowerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      siteId: json['site_id'] is int ? json['site_id'] : int.tryParse(json['site_id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 0,
      skilledWorker: json['skilled_worker'] is int ? json['skilled_worker'] : int.tryParse(json['skilled_worker'].toString()) ?? 0,
      unskilledWorker: json['unskilled_worker'] is int ? json['unskilled_worker'] : int.tryParse(json['unskilled_worker'].toString()) ?? 0,
      date: json['date']?.toString() ?? '',
      shift: json['shift'] is int ? json['shift'] : int.tryParse(json['shift'].toString()) ?? 1,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
      category: CategoryModel.fromJson(json['category'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'user_id': userId,
      'category_id': categoryId,
      'skilled_worker': skilledWorker,
      'unskilled_worker': unskilledWorker,
      'date': date,
      'shift': shift,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'category': category.toJson(),
    };
  }

  // Helper getters
  bool get isActive => deletedAt == null;
  int get totalWorkers => skilledWorker + unskilledWorker;
  String get shiftText {
    switch (shift) {
      case 1:
        return 'Day';
      case 2:
        return 'Night';
      case 3:
        return 'Day Night';
      default:
        return 'Day';
    }
  }
}
