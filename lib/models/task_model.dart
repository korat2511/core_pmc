import 'site_model.dart';
import 'user_model.dart';

class TaskModel {
  final int id;
  final String name;
  final String? notes;
  final String? comment;
  final int siteId;
  final int createdBy;
  final String? assignTo;
  final String? startDate;
  final String? endDate;
  final int? progress;
  final int totalWorkDone;
  final int totalWork;
  final int categoryId;
  final String? voiceNote;
  final String? totalPrice;
  final String? tag;
  final String status;
  final String unit;
  final String? decisionByAgency;
  final String? decisionPendingOther;
  final String? completionDate;
  final String? decisionPendingFrom;
  final int? qcCategoryId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int? taskId;
  final String? latestUpdate;
  final List<UserModel> assign;
  final String categoryName;
  final String createdByName;
  final String? voiceNotePath;
  final SiteModel site;

  TaskModel({
    required this.id,
    required this.name,
    this.notes,
    this.comment,
    required this.siteId,
    required this.createdBy,
    this.assignTo,
    this.startDate,
    this.endDate,
    this.progress,
    required this.totalWorkDone,
    required this.totalWork,
    required this.categoryId,
    this.voiceNote,
    this.totalPrice,
    this.tag,
    required this.status,
    required this.unit,
    this.decisionByAgency,
    this.decisionPendingOther,
    this.completionDate,
    this.decisionPendingFrom,
    this.qcCategoryId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.taskId,
    this.latestUpdate,
    required this.assign,
    required this.categoryName,
    required this.createdByName,
    this.voiceNotePath,
    required this.site,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      notes: json['notes'],
      comment: json['comment'],
      siteId: json['site_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      assignTo: json['assign_to'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      progress: json['progress'],
      totalWorkDone: json['total_work_done'] ?? 0,
      totalWork: json['total_work'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      voiceNote: json['voice_note'],
      totalPrice: json['total_price'],
      tag: json['tag'],
      status: json['status'] ?? '',
      unit: json['unit'] ?? '',
      decisionByAgency: json['decision_by_agency'],
      decisionPendingOther: json['decision_pending_other'],
      completionDate: json['completion_date'],
      decisionPendingFrom: json['decision_pending_from'],
      qcCategoryId: json['qc_category_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      taskId: json['task_id'],
      latestUpdate: json['latest_update'],
      assign: (json['assign'] as List<dynamic>?)
          ?.map((userJson) => UserModel.fromJson(userJson))
          .toList() ?? [],
      categoryName: json['category_name'] ?? '',
      createdByName: json['created_by_name'] ?? '',
      voiceNotePath: json['voice_note_path'],
      site: SiteModel.fromJson(json['site'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'comment': comment,
      'site_id': siteId,
      'created_by': createdBy,
      'assign_to': assignTo,
      'start_date': startDate,
      'end_date': endDate,
      'progress': progress,
      'total_work_done': totalWorkDone,
      'total_work': totalWork,
      'category_id': categoryId,
      'voice_note': voiceNote,
      'total_price': totalPrice,
      'tag': tag,
      'status': status,
      'unit': unit,
      'decision_by_agency': decisionByAgency,
      'decision_pending_other': decisionPendingOther,
      'completion_date': completionDate,
      'decision_pending_from': decisionPendingFrom,
      'qc_category_id': qcCategoryId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'task_id': taskId,
      'latest_update': latestUpdate,
      'assign': assign.map((user) => user.toJson()).toList(),
      'category_name': categoryName,
      'created_by_name': createdByName,
      'voice_note_path': voiceNotePath,
      'site': site.toJson(),
    };
  }

  // Helper getters
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isComplete => status.toLowerCase() == 'complete';
  bool get isOverdue => status.toLowerCase() == 'overdue';
  
  double get progressPercentage => progress?.toDouble() ?? 0.0;
  
  String get assignedUsersNames {
    if (assign.isEmpty) return 'Unassigned';
    return assign.map((user) => '${user.firstName} ${user.lastName}').join(', ');
  }
  
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'active':
        return 'In Progress';
      case 'complete':
        return 'Completed';
      case 'overdue':
        return 'Overdue';
      default:
        return status;
    }
  }

  TaskModel copyWith({
    int? id,
    String? name,
    String? notes,
    String? comment,
    int? siteId,
    int? createdBy,
    String? assignTo,
    String? startDate,
    String? endDate,
    int? progress,
    int? totalWorkDone,
    int? totalWork,
    int? categoryId,
    String? voiceNote,
    String? totalPrice,
    String? tag,
    String? status,
    String? unit,
    String? decisionByAgency,
    String? decisionPendingOther,
    String? completionDate,
    String? decisionPendingFrom,
    int? qcCategoryId,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    int? taskId,
    String? latestUpdate,
    List<UserModel>? assign,
    String? categoryName,
    String? createdByName,
    String? voiceNotePath,
    SiteModel? site,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      comment: comment ?? this.comment,
      siteId: siteId ?? this.siteId,
      createdBy: createdBy ?? this.createdBy,
      assignTo: assignTo ?? this.assignTo,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      totalWorkDone: totalWorkDone ?? this.totalWorkDone,
      totalWork: totalWork ?? this.totalWork,
      categoryId: categoryId ?? this.categoryId,
      voiceNote: voiceNote ?? this.voiceNote,
      totalPrice: totalPrice ?? this.totalPrice,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      unit: unit ?? this.unit,
      decisionByAgency: decisionByAgency ?? this.decisionByAgency,
      decisionPendingOther: decisionPendingOther ?? this.decisionPendingOther,
      completionDate: completionDate ?? this.completionDate,
      decisionPendingFrom: decisionPendingFrom ?? this.decisionPendingFrom,
      qcCategoryId: qcCategoryId ?? this.qcCategoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      taskId: taskId ?? this.taskId,
      latestUpdate: latestUpdate ?? this.latestUpdate,
      assign: assign ?? this.assign,
      categoryName: categoryName ?? this.categoryName,
      createdByName: createdByName ?? this.createdByName,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      site: site ?? this.site,
    );
  }
}
