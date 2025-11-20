class SiteGalleryImageModel {
  final int id;
  final String image;
  final String imagePath;
  final String source; // 'site', 'task', 'progress'
  final String sourceType; // 'Site', 'Task', 'Task Progress'
  final String? taskName;
  final int? taskId;
  final String uploadedBy;
  final int? uploadedById;
  final String? createdAt;

  SiteGalleryImageModel({
    required this.id,
    required this.image,
    required this.imagePath,
    required this.source,
    required this.sourceType,
    this.taskName,
    this.taskId,
    required this.uploadedBy,
    this.uploadedById,
    this.createdAt,
  });

  factory SiteGalleryImageModel.fromJson(Map<String, dynamic> json) {
    return SiteGalleryImageModel(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      imagePath: json['image_path'] ?? '',
      source: json['source'] ?? '',
      sourceType: json['source_type'] ?? '',
      taskName: json['task_name'],
      taskId: json['task_id'],
      uploadedBy: json['uploaded_by'] ?? 'Unknown',
      uploadedById: json['uploaded_by_id'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'image_path': imagePath,
      'source': source,
      'source_type': sourceType,
      'task_name': taskName,
      'task_id': taskId,
      'uploaded_by': uploadedBy,
      'uploaded_by_id': uploadedById,
      'created_at': createdAt,
    };
  }
}

