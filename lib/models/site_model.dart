class SiteImage {
  final int id;
  final int userId;
  final String image;
  final int siteId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String imagePath;

  SiteImage({
    required this.id,
    required this.userId,
    required this.image,
    required this.siteId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.imagePath,
  });

  factory SiteImage.fromJson(Map<String, dynamic> json) {
    return SiteImage(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      image: json['image'] ?? '',
      siteId: json['site_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      imagePath: json['image_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image': image,
      'site_id': siteId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image_path': imagePath,
    };
  }
}

class SiteModel {
  final int id;
  final String name;
  final String? clientName;
  final String? architectName;
  final String? address;
  final int? userId;
  final String company;
  final String? startDate;
  final String? endDate;
  final String status;
  final double? latitude;
  final double? longitude;
  final int minRange;
  final int maxRange;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final int isPinned;
  final int progress;
  final List<SiteImage> images;

  SiteModel({
    required this.id,
    required this.name,
    this.clientName,
    this.architectName,
    this.address,
    this.userId,
    required this.company,
    this.startDate,
    this.endDate,
    required this.status,
    this.latitude,
    this.longitude,
    required this.minRange,
    required this.maxRange,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.progress,
    required this.images,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      clientName: json['client_name'],
      architectName: json['architect_name'],
      address: json['address'],
      userId: json['user_id'],
      company: json['company'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      minRange: json['min_range'] ?? 0,
      maxRange: json['max_range'] ?? 0,
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isPinned: json['is_pinned'] ?? 0,
      progress: json['progress'] ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => SiteImage.fromJson(image))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'client_name': clientName,
      'architect_name': architectName,
      'address': address,
      'user_id': userId,
      'company': company,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'min_range': minRange,
      'max_range': maxRange,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_pinned': isPinned,
      'progress': progress,
      'images': images.map((image) => image.toJson()).toList(),
    };
  }

  // Helper methods
  bool get isActive => status.toLowerCase() == 'active';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isComplete => status.toLowerCase() == 'complete';
  bool get isOverdue => status.toLowerCase() == 'overdue';
  bool get hasImages => images.isNotEmpty;
  String? get firstImagePath => hasImages ? images.first.imagePath : null;

  // Copy with method for state management
  SiteModel copyWith({
    int? id,
    String? name,
    String? clientName,
    String? architectName,
    String? address,
    int? userId,
    String? company,
    String? startDate,
    String? endDate,
    String? status,
    double? latitude,
    double? longitude,
    int? minRange,
    int? maxRange,
    String? deletedAt,
    String? createdAt,
    String? updatedAt,
    int? isPinned,
    int? progress,
    List<SiteImage>? images,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      architectName: architectName ?? this.architectName,
      address: address ?? this.address,
      userId: userId ?? this.userId,
      company: company ?? this.company,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      minRange: minRange ?? this.minRange,
      maxRange: maxRange ?? this.maxRange,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      progress: progress ?? this.progress,
      images: images ?? this.images,
    );
  }
} 