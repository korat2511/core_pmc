class UnifiedImageModel {
  final int id;
  final String imagePath;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final ImageSource source;
  final int? taskId;
  final int? taskProgressId;

  UnifiedImageModel({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.source,
    this.taskId,
    this.taskProgressId,
  });

  factory UnifiedImageModel.fromTaskImage(Map<String, dynamic> json) {
    return UnifiedImageModel(
      id: json['id'] ?? 0,
      imagePath: json['image_path'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      source: ImageSource.taskImage,
      taskId: json['task_id'],
    );
  }

  factory UnifiedImageModel.fromProgressImage(Map<String, dynamic> json) {
    return UnifiedImageModel(
      id: json['id'] ?? 0,
      imagePath: json['image_path'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      source: ImageSource.progressImage,
      taskProgressId: json['task_progress_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'source': source.name,
      'task_id': taskId,
      'task_progress_id': taskProgressId,
    };
  }
}

enum ImageSource {
  taskImage,
  progressImage,
}
