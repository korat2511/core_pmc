class Issue {
  final int id;
  final int siteId;
  final int? companyId;
  final String linkType; // from_task, from_site, from_material, other
  final int? linkId;
  final int? taskId;
  final int? materialId;
  final int? agencyId;
  final String description;
  final DateTime? dueDate;
  final int? assignedTo;
  final int? tagId;
  final String status; // Open, working, QC, solved, done
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationships
  final Map<String, dynamic>? site;
  final Map<String, dynamic>? company;
  final Map<String, dynamic>? task;
  final Map<String, dynamic>? material;
  final Map<String, dynamic>? agency;
  final Map<String, dynamic>? assignedUser;
  final Map<String, dynamic>? createdUser;
  final Map<String, dynamic>? tag;
  final List<Map<String, dynamic>>? attachments;
  final List<Map<String, dynamic>>? comments;

  Issue({
    required this.id,
    required this.siteId,
    this.companyId,
    required this.linkType,
    this.linkId,
    this.taskId,
    this.materialId,
    this.agencyId,
    required this.description,
    this.dueDate,
    this.assignedTo,
    this.tagId,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.site,
    this.company,
    this.task,
    this.material,
    this.agency,
    this.assignedUser,
    this.createdUser,
    this.tag,
    this.attachments,
    this.comments,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: _parseInt(json['id']),
      siteId: _parseInt(json['site_id']),
      companyId: json['company_id'] != null ? _parseInt(json['company_id']) : null,
      linkType: json['link_type'] ?? '',
      linkId: json['link_id'] != null ? _parseInt(json['link_id']) : null,
      taskId: json['task_id'] != null ? _parseInt(json['task_id']) : null,
      materialId: json['material_id'] != null ? _parseInt(json['material_id']) : null,
      agencyId: json['agency_id'] != null ? _parseInt(json['agency_id']) : null,
      description: json['description'] ?? '',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      assignedTo: json['assigned_to'] != null 
          ? (json['assigned_to'] is String && (json['assigned_to'] as String).contains(',')
              ? _parseInt((json['assigned_to'] as String).split(',')[0]) // For backward compatibility, take first ID
              : _parseInt(json['assigned_to']))
          : null,
      tagId: json['tag_id'] != null 
          ? (json['tag_id'] is String && (json['tag_id'] as String).contains(',')
              ? _parseInt((json['tag_id'] as String).split(',')[0]) // For backward compatibility, take first ID
              : _parseInt(json['tag_id']))
          : null,
      status: json['status'] ?? 'Open',
      createdBy: _parseInt(json['created_by']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      site: json['site'] != null ? Map<String, dynamic>.from(json['site']) : null,
      company: json['company'] != null ? Map<String, dynamic>.from(json['company']) : null,
      task: json['task'] != null ? Map<String, dynamic>.from(json['task']) : null,
      material: json['material'] != null ? Map<String, dynamic>.from(json['material']) : null,
      agency: json['agency'] != null ? Map<String, dynamic>.from(json['agency']) : null,
      assignedUser: json['assigned_user'] != null 
          ? Map<String, dynamic>.from(json['assigned_user']) 
          : (json['assignedUser'] != null ? Map<String, dynamic>.from(json['assignedUser']) : null),
      createdUser: json['created_user'] != null 
          ? Map<String, dynamic>.from(json['created_user']) 
          : (json['createdUser'] != null ? Map<String, dynamic>.from(json['createdUser']) : null),
      tag: json['tag'] != null ? Map<String, dynamic>.from(json['tag']) : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : null,
      comments: json['comments'] != null
          ? (json['comments'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'company_id': companyId,
      'link_type': linkType,
      'link_id': linkId,
      'task_id': taskId,
      'material_id': materialId,
      'agency_id': agencyId,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'tag_id': tagId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class IssueComment {
  final int id;
  final int issueId;
  final int userId;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationships
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>>? images;

  IssueComment({
    required this.id,
    required this.issueId,
    required this.userId,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.images,
  });

  factory IssueComment.fromJson(Map<String, dynamic> json) {
    return IssueComment(
      id: _parseInt(json['id']),
      issueId: _parseInt(json['issue_id']),
      userId: _parseInt(json['user_id']),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? Map<String, dynamic>.from(json['user']) : null,
      images: json['images'] != null
          ? (json['images'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }
}

