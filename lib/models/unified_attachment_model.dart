class UnifiedAttachmentModel {
  final int id;
  final String attachmentPath;
  final String fileName;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final AttachmentSource source;
  final int? taskId;
  final int? taskProgressId;

  UnifiedAttachmentModel({
    required this.id,
    required this.attachmentPath,
    required this.fileName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.source,
    this.taskId,
    this.taskProgressId,
  });

  factory UnifiedAttachmentModel.fromTaskAttachment(String attachmentPath) {
    return UnifiedAttachmentModel(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID for task attachments
      attachmentPath: attachmentPath,
      fileName: attachmentPath.split('/').last,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      source: AttachmentSource.taskAttachment,
    );
  }

  factory UnifiedAttachmentModel.fromProgressAttachment(Map<String, dynamic> json) {
    return UnifiedAttachmentModel(
      id: json['id'] ?? 0,
      attachmentPath: json['attachment_path'] ?? '',
      fileName: json['attachment'] ?? json['attachment_path']?.split('/').last ?? 'Unknown',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      source: AttachmentSource.progressAttachment,
      taskProgressId: json['task_progress_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attachment_path': attachmentPath,
      'file_name': fileName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'source': source.name,
      'task_id': taskId,
      'task_progress_id': taskProgressId,
    };
  }

  // Helper methods
  String get fileExtension {
    // Try to get extension from fileName first
    final fileNameParts = fileName.split('.');
    if (fileNameParts.length > 1) {
      final ext = fileNameParts.last.toLowerCase().trim();
      if (ext.isNotEmpty && ext.length <= 4) {
        print('fileExtension from fileName: "$ext"');
        return ext;
      }
    }
    
    // Fallback to attachmentPath if fileName doesn't have extension
    final pathParts = attachmentPath.split('.');
    if (pathParts.length > 1) {
      final ext = pathParts.last.toLowerCase().trim();
      if (ext.isNotEmpty && ext.length <= 4) {
        print('fileExtension from attachmentPath: "$ext"');
        return ext;
      }
    }
    
    // If still no extension found, try to extract from the full path
    final fullPath = attachmentPath.isNotEmpty ? attachmentPath : fileName;
    final fullPathParts = fullPath.split('.');
    if (fullPathParts.length > 1) {
      final ext = fullPathParts.last.toLowerCase().trim();
      if (ext.isNotEmpty && ext.length <= 4) {
        print('fileExtension from fullPath: "$ext"');
        return ext;
      }
    }
    
    print('fileExtension: no extension found, returning empty string');
    return '';
  }

  bool get isPdf {
    final ext = fileExtension;
    print('isPdf check: ext="$ext", length=${ext.length}, equals pdf: ${ext == 'pdf'}');
    return ext == 'pdf';
  }
  bool get isExcel => fileExtension == 'xlsx' || fileExtension == 'xls';
  bool get isWord => fileExtension == 'doc' || fileExtension == 'docx';
  bool get isText => fileExtension == 'txt' || fileExtension == 'rtf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension);
  bool get isVideo => ['mp4', 'avi', 'mov', 'wmv'].contains(fileExtension);
  bool get isAudio => ['mp3', 'wav', 'aac'].contains(fileExtension);
  bool get isArchive => ['zip', 'rar', '7z'].contains(fileExtension);
  
  // Debug method to help troubleshoot file extension issues
  String get debugInfo {
    return '''
    fileName: $fileName
    attachmentPath: $attachmentPath
    fileExtension: $fileExtension
    isPdf: $isPdf
    ''';
  }
}

enum AttachmentSource {
  taskAttachment,
  progressAttachment,
}
