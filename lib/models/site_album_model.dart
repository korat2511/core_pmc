class SiteAlbumModel {
  final int id;
  final int siteId;
  final int? parentId;
  final String albumName;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final List<SiteAlbumModel> children;
  final List<SiteAlbumImage> images;

  SiteAlbumModel({
    required this.id,
    required this.siteId,
    this.parentId,
    required this.albumName,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.children,
    required this.images,
  });

  factory SiteAlbumModel.fromJson(Map<String, dynamic> json) {
    return SiteAlbumModel(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      parentId: json['parent_id'],
      albumName: json['album_name'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      children: (json['children'] as List<dynamic>?)
              ?.map((child) => SiteAlbumModel.fromJson(child))
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => SiteAlbumImage.fromJson(image))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'parent_id': parentId,
      'album_name': albumName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'children': children.map((child) => child.toJson()).toList(),
      'images': images.map((image) => image.toJson()).toList(),
    };
  }

  // Helper methods
  bool get isMainFolder => parentId == null;
  bool get isSubFolder => parentId != null;
  bool get hasChildren => children.isNotEmpty;
  bool get hasImages => images.isNotEmpty;
  bool get hasAttachments => images.any((img) => img.isAttachment);
  bool get hasOnlyImages => hasImages && !hasAttachments;
  bool get hasOnlyAttachments => hasAttachments && !images.any((img) => img.isImage);
  bool get hasMixedContent => hasImages && hasAttachments;

  int get totalItems => images.length;
  int get imageCount => images.where((img) => img.isImage).length;
  int get attachmentCount => images.where((img) => img.isAttachment).length;

  SiteAlbumModel copyWith({
    int? id,
    int? siteId,
    int? parentId,
    String? albumName,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    List<SiteAlbumModel>? children,
    List<SiteAlbumImage>? images,
  }) {
    return SiteAlbumModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      parentId: parentId ?? this.parentId,
      albumName: albumName ?? this.albumName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      children: children ?? this.children,
      images: images ?? this.images,
    );
  }
}

class SiteAlbumImage {
  final int id;
  final int subAlbumId;
  final String? image;
  final String? attachment;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? imagePath;
  final String? attachmentPath;

  SiteAlbumImage({
    required this.id,
    required this.subAlbumId,
    this.image,
    this.attachment,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.imagePath,
    this.attachmentPath,
  });

  factory SiteAlbumImage.fromJson(Map<String, dynamic> json) {
    return SiteAlbumImage(
      id: json['id'] ?? 0,
      subAlbumId: json['sub_album_id'] ?? 0,
      image: json['image'],
      attachment: json['attachment'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      imagePath: json['image_path'],
      attachmentPath: json['attachment_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sub_album_id': subAlbumId,
      'image': image,
      'attachment': attachment,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image_path': imagePath,
      'attachment_path': attachmentPath,
    };
  }

  // Helper methods
  bool get isImage => image != null && image!.isNotEmpty;
  bool get isAttachment => attachment != null && attachment!.isNotEmpty;
  String? get displayPath => imagePath ?? attachmentPath;
  String get fileName {
    if (isImage && image != null) {
      return image!.split('/').last;
    } else if (isAttachment && attachment != null) {
      return attachment!.split('/').last;
    }
    return 'Unknown';
  }

  String get fileExtension {
    final fileName = this.fileName;
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isPdf => fileExtension == 'pdf';
  bool get isExcel => fileExtension == 'xlsx' || fileExtension == 'xls';
  bool get isWord => fileExtension == 'doc' || fileExtension == 'docx';
  bool get isDwg => fileExtension == 'dwg';
  bool get isImageFile {
    final ext = fileExtension;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  SiteAlbumImage copyWith({
    int? id,
    int? subAlbumId,
    String? image,
    String? attachment,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? imagePath,
    String? attachmentPath,
  }) {
    return SiteAlbumImage(
      id: id ?? this.id,
      subAlbumId: subAlbumId ?? this.subAlbumId,
      image: image ?? this.image,
      attachment: attachment ?? this.attachment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      imagePath: imagePath ?? this.imagePath,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }
}
